#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <memory>
#include <string>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void ShowTrayMenu();
  void RestoreWindow();
  void SendAction(const std::string& action);
  bool AddTrayIcon();
  void RemoveTrayIcon();
  void ShowNotification(const std::string& message);
  bool quitting_ = false;
  bool paused_ = false;
  bool tray_added_ = false;
  std::wstring label_open_ = L"Open WatterReminder";
  std::wstring label_drink_ = L"Drink Water Now";
  std::wstring label_pause_ = L"Pause Reminders";
  std::wstring label_resume_ = L"Resume Reminders";
  std::wstring label_quit_ = L"Quit";
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
