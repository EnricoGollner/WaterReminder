# WatterReminder — Build Prompt

Build a Windows Desktop Flutter app called **WatterReminder** that lives in the Windows System Tray and reminds the user to drink water at a configurable interval.

## Existing Project Context

- The Flutter project is already initialized and the app icons are already in place:
  - `assets/app_icon.png` (512x512 transparent PNG)
  - `assets/app_icon.ico` (multi-resolution ICO)
  - `windows/runner/resources/app_icon.ico` (native Windows runner icon)
- Register `assets/` in `pubspec.yaml` and replace any placeholder dependencies in `lib/main.dart` with standard `package:flutter/material.dart`.

## Core Requirements

### 1. Configurable Countdown Timer

- Default interval is **30 minutes**, with quick presets (15m, 30m, 45m, 60m) and custom minute input.
- Show a live countdown until the next reminder, plus daily hydration intake counter (glasses drunk today).
- Provide buttons to Pause/Resume, Reset timer ("Just drank water"), and "Test Notification".
- Persist user settings locally (interval, custom reminder message, active state, daily count).

### 2. Native Windows Notifications

- When the countdown reaches zero, trigger a native Windows Toast / Tray Balloon notification displaying:
  - **App Name / Title:** `WatterReminder`
  - **Description:** Reminder message telling the user to drink water (default: `"Time to drink water! Take a quick break and stay hydrated."`, customizable in UI).
  - **App Icon:** `IDI_APP_ICON` / `app_icon.ico`.

### 3. Windows System Tray Integration & Close-to-Tray

- Display the app icon in the Windows System Tray.
- Intercept window close (`WM_CLOSE`): closing the window hides it to the System Tray instead of quitting the process.
- Left-clicking the tray icon restores and focuses the window.
- Right-clicking the tray icon opens a native context menu with:
  - Open WatterReminder
  - Drink Water Now (Reset Timer)
  - Pause / Resume Reminders
  - Quit (actually exits the app)

### 4. Implementation Details

- Implement the System Tray (`Shell_NotifyIconW`), native notification (`NIF_INFO`), context menu (`CreatePopupMenu`), and close-to-tray (`WM_CLOSE` interception) directly in the Windows C++ runner (`windows/runner/flutter_window.cpp` and `flutter_window.h`) bridged to Dart via `MethodChannel('watter_reminder/native')` so it compiles cleanly with zero external C++ plugin conflicts.
- Set the default window size in `windows/runner/main.cpp` to a compact desktop utility size (e.g., `480x660`).
- Design a polished, dark-ocean/glacier-blue desktop UI featuring a circular countdown ring, interval selector, custom notification message editor, and test notification button.

### 5. Multi-language Support (i18n)

- The app supports **Portuguese (PT)**, **English (EN)** and **Spanish (ES)**, switchable at runtime from a language selector in the main window header (no restart required).
- All UI texts, notices, the default reminder message and the native tray context menu labels are translated.
- The selected language is persisted in the local settings. If the reminder message is still the default one, it follows the selected language; custom messages are preserved.
- Translations live in `lib/l10n.dart`; the tray menu labels are sent to the C++ runner through the `configure` method of `MethodChannel('watter_reminder/native')`.

### 6. Notification Click

- Clicking the Windows notification (balloon/toast) opens, restores and focuses the application window (`NIN_BALLOONUSERCLICK`).
