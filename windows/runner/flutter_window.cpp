#include "flutter_window.h"

#include <optional>
#include <variant>
#include <shellapi.h>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"

namespace {
constexpr UINT kTrayMessage = WM_APP + 1;
constexpr UINT kTrayId = 1;
constexpr UINT kOpen = 1001;
constexpr UINT kDrink = 1002;
constexpr UINT kPause = 1003;
constexpr UINT kQuit = 1004;

std::wstring FromUtf8(const std::string& text) {
  if (text.empty()) return {};
  int size = MultiByteToWideChar(CP_UTF8, 0, text.c_str(),
                                 static_cast<int>(text.size()), nullptr, 0);
  if (size <= 0) return {};
  std::wstring result(size, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.c_str(),
                      static_cast<int>(text.size()), result.data(), size);
  return result;
}

template <size_t N>
void CopyText(wchar_t (&target)[N], const std::wstring& text) {
  wcsncpy_s(target, N, text.c_str(), _TRUNCATE);
}
}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "watter_reminder/native",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() == "showNotification") {
      const auto* message = std::get_if<std::string>(call.arguments());
      if (message) {
        ShowNotification(*message);
        result->Success();
      } else {
        result->Error("invalid_argument", "Expected a message string");
      }
    } else if (call.method_name() == "setPaused") {
      const auto* paused = std::get_if<bool>(call.arguments());
      if (paused) {
        paused_ = *paused;
        result->Success();
      } else {
        result->Error("invalid_argument", "Expected a boolean");
      }
    } else {
      result->NotImplemented();
    }
  });
  AddTrayIcon();

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  RemoveTrayIcon();
  channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_CLOSE && !quitting_) {
    ShowWindow(hwnd, SW_HIDE);
    return 0;
  }
  if (message == WM_DESTROY) RemoveTrayIcon();
  if (message == kTrayMessage) {
    const auto event = LOWORD(lparam);
    if (event == WM_LBUTTONUP || event == NIN_SELECT ||
        event == NIN_KEYSELECT) RestoreWindow();
    if (event == WM_RBUTTONUP || event == WM_CONTEXTMENU) ShowTrayMenu();
    return 0;
  }
  if (message == WM_COMMAND) {
    switch (LOWORD(wparam)) {
      case kOpen: RestoreWindow(); return 0;
      case kDrink: SendAction("drinkWater"); return 0;
      case kPause: SendAction("togglePause"); return 0;
      case kQuit:
        quitting_ = true;
        DestroyWindow(hwnd);
        return 0;
    }
  }
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
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
  data.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
  data.uCallbackMessage = kTrayMessage;
  data.hIcon = LoadIconW(GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON));
  CopyText(data.szTip, L"WatterReminder");
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

void FlutterWindow::ShowNotification(const std::string& message) {
  if (!tray_added_) AddTrayIcon();
  NOTIFYICONDATAW data{};
  data.cbSize = sizeof(data);
  data.hWnd = GetHandle();
  data.uID = kTrayId;
  data.uFlags = NIF_INFO;
  data.dwInfoFlags = NIIF_USER | NIIF_LARGE_ICON;
  data.hBalloonIcon = LoadIconW(GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON));
  CopyText(data.szInfoTitle, L"WatterReminder");
  CopyText(data.szInfo, FromUtf8(message));
  Shell_NotifyIconW(NIM_MODIFY, &data);
}

void FlutterWindow::RestoreWindow() {
  ShowWindow(GetHandle(), SW_RESTORE);
  SetForegroundWindow(GetHandle());
  SetFocus(GetHandle());
}

void FlutterWindow::SendAction(const std::string& action) {
  if (channel_) channel_->InvokeMethod(action, nullptr);
}

void FlutterWindow::ShowTrayMenu() {
  HMENU menu = CreatePopupMenu();
  if (!menu) return;
  AppendMenuW(menu, MF_STRING, kOpen, L"Open WatterReminder");
  AppendMenuW(menu, MF_STRING, kDrink, L"Drink Water Now");
  AppendMenuW(menu, MF_STRING, kPause,
              paused_ ? L"Resume Reminders" : L"Pause Reminders");
  AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  AppendMenuW(menu, MF_STRING, kQuit, L"Quit");
  POINT point{};
  GetCursorPos(&point);
  SetForegroundWindow(GetHandle());
  TrackPopupMenu(menu, TPM_BOTTOMALIGN | TPM_LEFTALIGN | TPM_RIGHTBUTTON,
                 point.x, point.y, 0, GetHandle(), nullptr);
  PostMessage(GetHandle(), WM_NULL, 0, 0);
  DestroyMenu(menu);
}
