# WaterReminder — Build Prompt

Build a Windows Desktop Flutter app called **WaterReminder** that lives in the Windows System Tray and reminds the user to drink water at a configurable interval.

> Renamed from *WatterReminder* (v0.1) to **WaterReminder** (v0.2). Settings saved by v0.1 in `%APPDATA%\WatterReminder` are migrated automatically.

## Existing Project Context

- The Flutter project is already initialized and the app icons are already in place:
  - `assets/app_icon.png` (512x512 transparent PNG)
  - `assets/app_icon.ico` (multi-resolution ICO)
  - `windows/runner/resources/app_icon.ico` (native Windows runner icon)
- Register `assets/` in `pubspec.yaml` and use the standard `package:flutter/material.dart`.

## Core Requirements

### 1. Configurable Countdown Timer

- Default interval is **30 minutes**, with quick presets (15m, 30m, 45m, 60m) and custom minute input (1–1440).
- Show a live countdown until the next reminder, plus the daily intake (ml and glasses).
- Provide buttons to Pause/Resume, "I drank" (logs a glass and resets the timer), Snooze 5 min, Undo last glass and "Test Notification".
- Persist settings, timer state and history locally in `%APPDATA%\WaterReminder\settings.json`.

### 2. Native Windows Notifications

- When the countdown reaches zero, show a native Windows **toast** with:
  - **Title:** `WaterReminder`
  - **Message:** default `"Time to drink water! Take a quick break and stay hydrated."` (translated), a custom message, or a random hydration tip.
  - **App icon:** `app_icon.png` / `IDI_APP_ICON`.
  - **Buttons:** "I drank" (logs a glass) and "Snooze 5 min".
- The toast uses the AppUserModelID `WaterReminder.App`, registered under `HKCU\Software\Classes\AppUserModelId`.
- If toasts are unavailable, fall back to a tray balloon (`NIF_INFO`).
- Optional notification sound (toggle).

### 3. Windows System Tray Integration & Close-to-Tray

- Display the app icon in the Windows System Tray; it turns grayscale while reminders are paused.
- The tray tooltip shows the time left and today's intake (e.g. `WaterReminder · 12 min · 750/2000 ml`).
- Intercept window close (`WM_CLOSE`): closing the window hides it to the tray instead of quitting.
- Left-clicking the tray icon restores and focuses the window.
- Right-clicking the tray icon opens a native context menu with:
  - Open WaterReminder
  - Drink Water Now
  - Snooze 5 Minutes
  - Pause / Resume Reminders
  - Quit (actually exits the app)
- Re-add the tray icon when Explorer restarts (`TaskbarCreated`).

### 4. Implementation Details

- Implement the tray (`Shell_NotifyIconW`), notifications (C++/WinRT toast, `NIF_INFO` fallback), context menu (`CreatePopupMenu`), close-to-tray, global hotkey, autostart and focus detection directly in the Windows C++ runner (`windows/runner/flutter_window.cpp`, `toast.cpp`), bridged to Dart via `MethodChannel('water_reminder/native')`, with zero external C++ plugins.
- Channel methods (Dart → C++): `showNotification`, `configure`, `updateTray`, `isUserBusy`, `getAutostart`, `setAutostart`, `setHotkey`. Callbacks (C++ → Dart): `drinkWater`, `togglePause`, `snooze`.
- Default window size in `windows/runner/main.cpp`: `480x720`.
- Polished dark-ocean/glacier-blue UI with a light variant.

### 5. Multi-language Support (i18n)

- Portuguese (PT), English (EN) and Spanish (ES), switchable at runtime (no restart), plus a "System" option.
- On first run the language follows the Windows language.
- All UI texts, notices, notification messages, tips, tray menu and toast buttons are translated.
- The selected language is persisted. Custom messages are preserved across languages.
- Translations live in `lib/src/reminder/presentation/l10n/`.

### 6. Notification Click

- Clicking the notification (toast body or balloon, `NIN_BALLOONUSERCLICK`) opens, restores and focuses the window.

### 7. Daily Goal and Glass Size

- Daily goal in ml (default 2000) with a water-wave progress indicator that fills as the goal is reached, and a message when the goal is reached.
- Configurable glass size (presets 200/250/300/500 ml or custom); intake is logged in ml.
- Suggested goal from weight and activity level: `35 ml × kg + activity bonus (0 / 350 / 700 ml)`, rounded to 50 ml.

### 8. History

- Bar chart of the last 7 or 30 days with the goal line; days that hit the goal are highlighted.
- Goal streak (consecutive days on goal), daily average and days on goal. History keeps 90 days.

### 9. Smarter Reminders

- **Active hours:** optional start/end time (overnight ranges supported); outside them, reminders are skipped.
- **Adaptive interval:** when intake is below 80% of the expected amount for the time of day, the interval drops to 2/3 (minimum 5 min).
- **Focus mode:** while the user is in full screen, a game, a presentation or Do Not Disturb (`SHQueryUserNotificationState`), the reminder is retried every minute.
- **Varied tips:** optionally show a random hydration tip instead of the fixed message.

### 10. System Integration

- **Start with Windows:** `HKCU\...\CurrentVersion\Run` entry launching `water_reminder.exe --minimized` (starts hidden in the tray).
- **Single instance:** a second launch brings the running window to the front and exits.
- **Global hotkey:** `Ctrl+Alt+W` logs a glass from anywhere (toggle; warns if the shortcut is taken).

### 11. Appearance

- Theme: System, Light or Dark.

### 12. Architecture and Quality

- Vertical slice `lib/src/reminder/{domain,data,presentation}` with Riverpod 3 (`InjectorContainer`), immutable states and Equatable entities.
- Typography in `lib/src/core/theme/fonts.dart` rendered through `UIText`; colors in `colors.dart`.
- Unit tests for domain rules, DTO migration, repository and controller; widget test for language switching.
- Windows installer (Inno Setup, `installer/water_reminder.iss`) and GitHub Actions CI that analyzes, tests, builds and packages the installer.
