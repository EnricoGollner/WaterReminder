#ifndef RUNNER_TOAST_H_
#define RUNNER_TOAST_H_

#include <windows.h>

#include <string>

// AppUserModelID used for toasts, the taskbar and the Start menu.
inline constexpr wchar_t kAppUserModelId[] = L"WaterReminder.App";

// Toast activation codes posted to the window as WPARAM of the callback message.
enum class ToastActivation : WPARAM { kOpen = 0, kDrink = 1, kSnooze = 2 };

// Text shown on a toast and its buttons.
struct ToastContent {
  std::wstring title;
  std::wstring message;
  std::wstring drink_label;
  std::wstring snooze_label;
  bool sound = true;
};

// Sets the process AppUserModelID and registers it under
// HKCU\Software\Classes\AppUserModelId so unpackaged toasts show the app name
// and icon. Safe to call on every start.
void RegisterToastIdentity(const std::wstring& icon_path);

// Shows a Windows toast with "drink" and "snooze" buttons. Activations are
// posted to |window| as |callback_message| with a ToastActivation in WPARAM.
// Returns false when toasts are unavailable, so callers can fall back to a
// tray balloon.
bool ShowToast(HWND window, UINT callback_message, const ToastContent& content,
               const std::wstring& icon_path);

#endif  // RUNNER_TOAST_H_
