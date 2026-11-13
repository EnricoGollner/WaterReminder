#include "flutter_window.h"

#include <flutter/standard_method_codec.h>
#include <shellapi.h>

#include <optional>
#include <variant>
#include <vector>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"
#include "toast.h"

namespace {
constexpr UINT kTrayMessage = WM_APP + 1;
constexpr UINT kToastMessage = WM_APP + 2;
constexpr UINT kTrayId = 1;
constexpr int kHotkeyId = 1;
constexpr UINT kOpen = 1001;
constexpr UINT kDrink = 1002;
constexpr UINT kPause = 1003;
constexpr UINT kQuit = 1004;
constexpr UINT kSnooze = 1005;
constexpr wchar_t kRunKey[] = L"Software\\Microsoft\\Windows\\CurrentVersion\\Run";
constexpr wchar_t kRunValue[] = L"WaterReminder";

std::wstring FromUtf8(const std::string& text) {
  if (text.empty()) return {};
  int size = MultiByteToWideChar(CP_UTF8, 0, text.c_str(), static_cast<int>(text.size()), nullptr, 0);
  if (size <= 0) return {};
  std::wstring result(size, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.c_str(), static_cast<int>(text.size()), result.data(), size);
  return result;
}

template <size_t N>
void CopyText(wchar_t (&target)[N], const std::wstring& text) {
  wcsncpy_s(target, N, text.c_str(), _TRUNCATE);
}

std::wstring ExePath() {
  std::wstring path(MAX_PATH, L'\0');
  DWORD size = GetModuleFileNameW(nullptr, path.data(), static_cast<DWORD>(path.size()));
  path.resize(size);
  return path;
}

std::wstring IconPngPath() {
  std::wstring exe = ExePath();
  return exe.substr(0, exe.find_last_of(L'\\')) + L"\\data\\flutter_assets\\assets\\app_icon.png";
}

const flutter::EncodableValue* Find(const flutter::EncodableMap& map, const char* key) {
  auto it = map.find(flutter::EncodableValue(key));
  return it == map.end() ? nullptr : &it->second;
}

void ReadText(const flutter::EncodableMap& map, const char* key, std::wstring& target) {
  if (const auto* value = Find(map, key)) {
    if (const auto* text = std::get_if<std::string>(value)) target = FromUtf8(*text);
  }
}

void ReadBool(const flutter::EncodableMap& map, const char* key, bool& target) {
  if (const auto* value = Find(map, key)) {
    if (const auto* flag = std::get_if<bool>(value)) target = *flag;
  }
}

// Builds a dimmed grayscale copy of |source| for the paused tray state.
HICON CreateGrayIcon(HICON source) {
  ICONINFO info{};
  if (!source || !GetIconInfo(source, &info)) return nullptr;
  HICON result = nullptr;
  BITMAP bitmap{};
  if (info.hbmColor && GetObject(info.hbmColor, sizeof(bitmap), &bitmap)) {
    const int width = bitmap.bmWidth, height = bitmap.bmHeight;
    BITMAPINFO bmi{};
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = width;
    bmi.bmiHeader.biHeight = -height;
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;
    std::vector<DWORD> pixels(static_cast<size_t>(width) * height);
    HDC dc = GetDC(nullptr);
    if (GetDIBits(dc, info.hbmColor, 0, height, pixels.data(), &bmi, DIB_RGB_COLORS)) {
      for (auto& p : pixels) {
        const DWORD a = p >> 24, r = (p >> 16) & 0xFF, g = (p >> 8) & 0xFF, b = p & 0xFF;
        const DWORD gray = ((r * 30 + g * 59 + b * 11) / 100) * 3 / 4;
        p = (a << 24) | (gray << 16) | (gray << 8) | gray;
      }
      void* bits = nullptr;
      HBITMAP color = CreateDIBSection(dc, &bmi, DIB_RGB_COLORS, &bits, nullptr, 0);
      if (color && bits) {
        memcpy(bits, pixels.data(), pixels.size() * sizeof(DWORD));
        ICONINFO gray_info = info;
        gray_info.hbmColor = color;
        result = CreateIconIndirect(&gray_info);
      }
      if (color) DeleteObject(color);
    }
    ReleaseDC(nullptr, dc);
  }
  if (info.hbmColor) DeleteObject(info.hbmColor);
  if (info.hbmMask) DeleteObject(info.hbmMask);
  return result;
}

bool GetAutostart() {
  HKEY key = nullptr;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kRunKey, 0, KEY_QUERY_VALUE, &key) != ERROR_SUCCESS) return false;
  const bool exists = RegQueryValueExW(key, kRunValue, nullptr, nullptr, nullptr, nullptr) == ERROR_SUCCESS;
  RegCloseKey(key);
  return exists;
}

bool SetAutostart(bool enabled) {
  HKEY key = nullptr;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kRunKey, 0, nullptr, 0, KEY_SET_VALUE, nullptr, &key, nullptr) != ERROR_SUCCESS) return false;
  LSTATUS status;
  if (enabled) {
    const std::wstring command = L"\"" + ExePath() + L"\" --minimized";
    status = RegSetValueExW(key, kRunValue, 0, REG_SZ, reinterpret_cast<const BYTE*>(command.c_str()),
                            static_cast<DWORD>((command.size() + 1) * sizeof(wchar_t)));
  } else {
    status = RegDeleteValueW(key, kRunValue);
    if (status == ERROR_FILE_NOT_FOUND) status = ERROR_SUCCESS;
  }
  RegCloseKey(key);
  return status == ERROR_SUCCESS;
}

bool IsUserBusy() {
  QUERY_USER_NOTIFICATION_STATE state{};
  if (FAILED(SHQueryUserNotificationState(&state))) return false;
  return state == QUNS_BUSY || state == QUNS_RUNNING_D3D_FULL_SCREEN || state == QUNS_PRESENTATION_MODE;
}

UINT TaskbarCreatedMessage() {
  static const UINT message = RegisterWindowMessageW(L"TaskbarCreated");
  return message;
}
}  // namespace

UINT FlutterWindow::ShowMessage() {
  static const UINT message = RegisterWindowMessageW(L"WaterReminder.Show");
  return message;
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project) : project_(project) {}

FlutterWindow::~FlutterWindow() {
  if (icon_) DestroyIcon(icon_);
  if (paused_icon_) DestroyIcon(paused_icon_);
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  RegisterToastIdentity(IconPngPath());
  channel_ = std::make_unique<Channel>(flutter_controller_->engine()->messenger(), "water_reminder/native", &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) { HandleMethodCall(call, std::move(result)); });

  const int size_x = GetSystemMetrics(SM_CXSMICON), size_y = GetSystemMetrics(SM_CYSMICON);
  icon_ = static_cast<HICON>(LoadImageW(GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON), IMAGE_ICON, size_x, size_y, 0));
  paused_icon_ = CreateGrayIcon(icon_);
  AddTrayIcon();

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    if (!start_hidden_) this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  SetHotkey(false);
  RemoveTrayIcon();
  channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

void FlutterWindow::HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call, Result result) {
  const std::string& method = call.method_name();
  const auto* args = call.arguments();
  const auto* map = args ? std::get_if<flutter::EncodableMap>(args) : nullptr;
  const auto* flag = args ? std::get_if<bool>(args) : nullptr;

  if (method == "showNotification") {
    if (!map) return result->Error("invalid_argument", "Expected a map");
    std::wstring title = L"WaterReminder", message;
    bool sound = true;
    ReadText(*map, "title", title);
    ReadText(*map, "message", message);
    ReadBool(*map, "sound", sound);
    if (ShowNotification(title, message, sound)) return result->Success();
    return result->Error("notification_failed", "Windows could not show the notification");
  }
  if (method == "configure") {
    if (!map) return result->Error("invalid_argument", "Expected a map");
    ReadBool(*map, "paused", paused_);
    ReadText(*map, "open", label_open_);
    ReadText(*map, "drink", label_drink_);
    ReadText(*map, "snooze", label_snooze_);
    ReadText(*map, "pause", label_pause_);
    ReadText(*map, "resume", label_resume_);
    ReadText(*map, "quit", label_quit_);
    ReadText(*map, "drankAction", label_drank_action_);
    ReadText(*map, "snoozeAction", label_snooze_action_);
    UpdateTrayIcon();
    return result->Success();
  }
  if (method == "updateTray") {
    if (!map) return result->Error("invalid_argument", "Expected a map");
    ReadText(*map, "tooltip", tooltip_);
    ReadBool(*map, "paused", paused_);
    UpdateTrayIcon();
    return result->Success();
  }
  if (method == "isUserBusy") return result->Success(flutter::EncodableValue(IsUserBusy()));
  if (method == "getAutostart") return result->Success(flutter::EncodableValue(GetAutostart()));
  if (method == "setAutostart") {
    if (!flag) return result->Error("invalid_argument", "Expected a boolean");
    return result->Success(flutter::EncodableValue(SetAutostart(*flag)));
  }
  if (method == "setHotkey") {
    if (!flag) return result->Error("invalid_argument", "Expected a boolean");
    return result->Success(flutter::EncodableValue(SetHotkey(*flag)));
  }
  result->NotImplemented();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message, WPARAM const wparam, LPARAM const lparam) noexcept {
  if (message == WM_CLOSE && !quitting_) {
    ShowWindow(hwnd, SW_HIDE);
    return 0;
  }
  if (message == ShowMessage()) {
    RestoreWindow();
    return 0;
  }
  if (message == TaskbarCreatedMessage()) {
    // Explorer restarted: the tray icon must be added again.
    tray_added_ = false;
    AddTrayIcon();
    return 0;
  }
  if (message == WM_DESTROY) RemoveTrayIcon();
  if (message == kTrayMessage) {
    const auto event = LOWORD(lparam);
    if (event == WM_LBUTTONUP || event == NIN_SELECT || event == NIN_KEYSELECT || event == NIN_BALLOONUSERCLICK) {
      RestoreWindow();
    }
    if (event == WM_RBUTTONUP || event == WM_CONTEXTMENU) ShowTrayMenu();
    return 0;
  }
  if (message == kToastMessage) {
    switch (static_cast<ToastActivation>(wparam)) {
      case ToastActivation::kDrink: SendAction("drinkWater"); break;
      case ToastActivation::kSnooze: SendAction("snooze"); break;
      default: RestoreWindow();
    }
    return 0;
  }
  if (message == WM_HOTKEY && wparam == kHotkeyId) {
    SendAction("drinkWater");
    return 0;
  }
  if (message == WM_COMMAND) {
    switch (LOWORD(wparam)) {
      case kOpen: RestoreWindow(); return 0;
      case kDrink: SendAction("drinkWater"); return 0;
      case kSnooze: SendAction("snooze"); return 0;
      case kPause: SendAction("togglePause"); return 0;
      case kQuit:
        quitting_ = true;
        DestroyWindow(hwnd);
        return 0;
    }
  }
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result = flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      if (flutter_controller_) flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

bool FlutterWindow::AddTrayIcon() {
  NOTIFYICONDATAW data{};
  data.cbSize = sizeof(data);
  data.hWnd = GetHandle();
  data.uID = kTrayId;
  data.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP | NIF_SHOWTIP;
  data.uCallbackMessage = kTrayMessage;
  data.hIcon = paused_ && paused_icon_ ? paused_icon_ : icon_;
  CopyText(data.szTip, tooltip_);
  tray_added_ = Shell_NotifyIconW(NIM_ADD, &data) != FALSE;
  if (tray_added_) {
    data.uVersion = NOTIFYICON_VERSION_4;
    Shell_NotifyIconW(NIM_SETVERSION, &data);
  }
  return tray_added_;
}

void FlutterWindow::RemoveTrayIcon() {
  if (!tray_added_) return;
  NOTIFYICONDATAW data{};
  data.cbSize = sizeof(data);
  data.hWnd = GetHandle();
  data.uID = kTrayId;
  Shell_NotifyIconW(NIM_DELETE, &data);
  tray_added_ = false;
}

void FlutterWindow::UpdateTrayIcon() {
  if (!tray_added_ && !AddTrayIcon()) return;
  NOTIFYICONDATAW data{};
  data.cbSize = sizeof(data);
  data.hWnd = GetHandle();
  data.uID = kTrayId;
  data.uFlags = NIF_ICON | NIF_TIP | NIF_SHOWTIP;
  data.hIcon = paused_ && paused_icon_ ? paused_icon_ : icon_;
  CopyText(data.szTip, tooltip_);
  Shell_NotifyIconW(NIM_MODIFY, &data);
}

bool FlutterWindow::ShowNotification(const std::wstring& title, const std::wstring& message, bool sound) {
  ToastContent content{title, message, label_drank_action_, label_snooze_action_, sound};
  if (ShowToast(GetHandle(), kToastMessage, content, IconPngPath())) return true;

  // Fallback: classic tray balloon (clicking it restores the window).
  if (!tray_added_ && !AddTrayIcon()) return false;
  NOTIFYICONDATAW data{};
  data.cbSize = sizeof(data);
  data.hWnd = GetHandle();
  data.uID = kTrayId;
  data.uFlags = NIF_INFO;
  data.dwInfoFlags = NIIF_USER | NIIF_LARGE_ICON | (sound ? 0 : NIIF_NOSOUND);
  data.hBalloonIcon = LoadIconW(GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON));
  CopyText(data.szInfoTitle, title);
  CopyText(data.szInfo, message);
  return Shell_NotifyIconW(NIM_MODIFY, &data) != FALSE;
}

bool FlutterWindow::SetHotkey(bool enabled) {
  if (enabled == hotkey_registered_) return true;
  if (enabled) {
    hotkey_registered_ = RegisterHotKey(GetHandle(), kHotkeyId, MOD_CONTROL | MOD_ALT | MOD_NOREPEAT, 'W') != FALSE;
    return hotkey_registered_;
  }
  if (GetHandle()) UnregisterHotKey(GetHandle(), kHotkeyId);
  hotkey_registered_ = false;
  return true;
}

void FlutterWindow::RestoreWindow() {
  ShowWindow(GetHandle(), SW_RESTORE);
  ShowWindow(GetHandle(), SW_SHOW);
  SetForegroundWindow(GetHandle());
  SetFocus(GetHandle());
}

void FlutterWindow::SendAction(const std::string& action) {
  if (channel_) channel_->InvokeMethod(action, nullptr);
}

void FlutterWindow::ShowTrayMenu() {
  HMENU menu = CreatePopupMenu();
  if (!menu) return;
  AppendMenuW(menu, MF_STRING, kOpen, label_open_.c_str());
  AppendMenuW(menu, MF_STRING, kDrink, label_drink_.c_str());
  AppendMenuW(menu, MF_STRING, kSnooze, label_snooze_.c_str());
  AppendMenuW(menu, MF_STRING, kPause, paused_ ? label_resume_.c_str() : label_pause_.c_str());
  AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  AppendMenuW(menu, MF_STRING, kQuit, label_quit_.c_str());
  POINT point{};
  GetCursorPos(&point);
  SetForegroundWindow(GetHandle());
  TrackPopupMenu(menu, TPM_BOTTOMALIGN | TPM_LEFTALIGN | TPM_RIGHTBUTTON, point.x, point.y, 0, GetHandle(), nullptr);
  PostMessage(GetHandle(), WM_NULL, 0, 0);
  DestroyMenu(menu);
}
