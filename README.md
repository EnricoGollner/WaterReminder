# WaterReminder

Windows tray app built with Flutter that reminds you to drink water.

- Countdown with presets, custom interval, pause, snooze and "I drank"
- Native toasts with **I drank** / **Snooze** buttons (tray balloon fallback)
- Daily goal in ml, glass size, suggested goal by weight and activity
- 7/30-day history with goal streak
- Active hours, adaptive interval, focus mode, varied tips, sound toggle
- Start with Windows, single instance, global shortcut `Ctrl+Alt+W`
- Portuguese, English and Spanish; light/dark theme

Full requirements: [docs/REQUISITOS.md](docs/REQUISITOS.md).

## Run

```bash
flutter run -d windows
```

## Test

```bash
flutter analyze
flutter test
```

## Build the installer

Requires [Inno Setup 6](https://jrsoftware.org/isinfo.php):

```bash
flutter build windows --release
iscc installer/water_reminder.iss
```

The installer is written to `build/installer/`. CI (`.github/workflows/windows.yml`) does the same on every push and uploads it as an artifact.
