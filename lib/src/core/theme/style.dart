import 'package:flutter/material.dart';

import 'colors.dart';

/// Temas claro e escuro do aplicativo.
abstract final class Style {
  static ThemeData get dark => _build(.dark, AppColors.darkBackground, AppColors.darkPanel, AppColors.darkTrack, AppColors.darkPrimary, AppColors.darkMuted, AppColors.darkBackground);

  static ThemeData get light => _build(.light, AppColors.lightBackground, AppColors.lightPanel, AppColors.lightTrack, AppColors.lightPrimary, AppColors.lightMuted, Colors.white);

  static ThemeData _build(Brightness brightness, Color background, Color panel, Color track, Color primary, Color muted, Color onPrimary) {
    final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: brightness).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      surface: background,
      surfaceContainer: panel,
      surfaceContainerHighest: track,
      onSurfaceVariant: muted,
      error: AppColors.error,
    );
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary.withValues(alpha: .25)));
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: panel, isDense: true, border: border, enabledBorder: border),
      navigationBarTheme: NavigationBarThemeData(backgroundColor: panel, indicatorColor: primary.withValues(alpha: .2), height: 62),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
