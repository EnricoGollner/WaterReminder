#include "toast.h"

#include <shobjidl.h>

#include <optional>

#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.UI.Notifications.h>

namespace {

using winrt::Windows::Data::Xml::Dom::XmlDocument;
using winrt::Windows::UI::Notifications::ToastActivatedEventArgs;
using winrt::Windows::UI::Notifications::ToastNotification;
using winrt::Windows::UI::Notifications::ToastNotificationManager;

// Keeps the last toast alive so its Activated handler stays registered.
std::optional<ToastNotification> g_last_toast;

std::wstring EscapeXml(const std::wstring& text) {
  std::wstring out;
  out.reserve(text.size());
  for (wchar_t c : text) {
    switch (c) {
      case L'&': out += L"&amp;"; break;
      case L'<': out += L"&lt;"; break;
      case L'>': out += L"&gt;"; break;
      case L'"': out += L"&quot;"; break;
      case L'\'': out += L"&apos;"; break;
      default: out += c;
    }
  }
  return out;
}

std::wstring FileUri(std::wstring path) {
  for (auto& c : path) {
    if (c == L'\\') c = L'/';
  }
  return L"file:///" + path;
}

void SetRegistryString(HKEY key, const wchar_t* name, const std::wstring& value) {
  RegSetValueExW(key, name, 0, REG_SZ, reinterpret_cast<const BYTE*>(value.c_str()),
                 static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t)));
}

}  // namespace

void RegisterToastIdentity(const std::wstring& icon_path) {
  SetCurrentProcessExplicitAppUserModelID(kAppUserModelId);
  const std::wstring key_path = std::wstring(L"Software\\Classes\\AppUserModelId\\") + kAppUserModelId;
  HKEY key = nullptr;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, key_path.c_str(), 0, nullptr, 0, KEY_SET_VALUE, nullptr, &key, nullptr) != ERROR_SUCCESS) {
    return;
  }
  SetRegistryString(key, L"DisplayName", L"WaterReminder");
  SetRegistryString(key, L"IconUri", icon_path);
  RegCloseKey(key);
}

bool ShowToast(HWND window, UINT callback_message, const ToastContent& content, const std::wstring& icon_path) {
  try {
    std::wstring xml = L"<toast launch=\"action=open\"><visual><binding template=\"ToastGeneric\">";
    xml += L"<text>" + EscapeXml(content.title) + L"</text>";
    xml += L"<text>" + EscapeXml(content.message) + L"</text>";
    xml += L"<image placement=\"appLogoOverride\" src=\"" + EscapeXml(FileUri(icon_path)) + L"\"/>";
    xml += L"</binding></visual><actions>";
    xml += L"<action content=\"" + EscapeXml(content.drink_label) + L"\" arguments=\"action=drink\" activationType=\"foreground\"/>";
    xml += L"<action content=\"" + EscapeXml(content.snooze_label) + L"\" arguments=\"action=snooze\" activationType=\"foreground\"/>";
    xml += L"</actions>";
    xml += content.sound ? L"<audio src=\"ms-winsoundevent:Notification.Default\"/>" : L"<audio silent=\"true\"/>";
    xml += L"</toast>";

    XmlDocument document;
    document.LoadXml(xml);
    ToastNotification toast(document);
    toast.Activated([window, callback_message](const ToastNotification&, const winrt::Windows::Foundation::IInspectable& args) {
      auto activation = ToastActivation::kOpen;
      if (auto activated = args.try_as<ToastActivatedEventArgs>()) {
        const std::wstring arguments = activated.Arguments().c_str();
        if (arguments == L"action=drink") activation = ToastActivation::kDrink;
        if (arguments == L"action=snooze") activation = ToastActivation::kSnooze;
      }
      // Activated runs on a background thread; hand it to the UI thread.
      PostMessageW(window, callback_message, static_cast<WPARAM>(activation), 0);
    });
    ToastNotificationManager::CreateToastNotifier(kAppUserModelId).Show(toast);
    g_last_toast = toast;
    return true;
  } catch (...) {
    return false;
  }
}
