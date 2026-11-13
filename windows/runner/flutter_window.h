#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <memory>
#include <string>

#include "win32_window.h"

// Hosts the Flutter view and owns the tray icon, notifications, global hotkey
// and close-to-tray behavior, bridged to Dart through the
// "water_reminder/native" method channel.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

  // Keeps the window hidden after the first frame (used by --minimized).
  void SetStartHidden(bool hidden) { start_hidden_ = hidden; }

  // Message another instance posts to bring this window to the front.
  static UINT ShowMessage();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  using Channel = flutter::MethodChannel<flutter::EncodableValue>;
  using Result = std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>;

  void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call, Result result);
  void ShowTrayMenu();
  void RestoreWindow();
  void SendAction(const std::string& action);
  bool AddTrayIcon();
  void RemoveTrayIcon();
  void UpdateTrayIcon();
  bool ShowNotification(const std::wstring& title, const std::wstring& message, bool sound);
  bool SetHotkey(bool enabled);

  bool quitting_ = false;
  bool paused_ = false;
  bool tray_added_ = false;
  bool start_hidden_ = false;
  bool hotkey_registered_ = false;
  HICON icon_ = nullptr;
  HICON paused_icon_ = nullptr;
  std::wstring tooltip_ = L"WaterReminder";
  std::wstring label_open_ = L"Open WaterReminder";
  std::wstring label_drink_ = L"Drink Water Now";
  std::wstring label_snooze_ = L"Snooze 5 Minutes";
  std::wstring label_pause_ = L"Pause Reminders";
  std::wstring label_resume_ = L"Resume Reminders";
  std::wstring label_quit_ = L"Quit";
  std::wstring label_drank_action_ = L"I drank";
  std::wstring label_snooze_action_ = L"Snooze 5 min";
  std::unique_ptr<Channel> channel_;

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
