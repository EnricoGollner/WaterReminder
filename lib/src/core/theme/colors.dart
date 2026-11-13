import 'package:flutter/material.dart';

/// Paleta oceano/glacial do aplicativo.
abstract final class AppColors {
  // Tema escuro.
  static const darkBackground = Color(0xFF071923);
  static const darkPanel = Color(0xFF102B39);
  static const darkTrack = Color(0xFF244351);
  static const darkPrimary = Color(0xFF78DBEE);
  static const darkMuted = Color(0xFF9AB8C3);

  // Tema claro.
  static const lightBackground = Color(0xFFEAF5F9);
  static const lightPanel = Color(0xFFFFFFFF);
  static const lightTrack = Color(0xFFCFE6EE);
  static const lightPrimary = Color(0xFF0A7EA4);
  static const lightMuted = Color(0xFF557A88);

  // Comuns.
  static const wave = Color(0xFF3FB6D9);
  static const waveDeep = Color(0xFF1F8FB8);
  static const success = Color(0xFF4CC38A);
  static const error = Color(0xFFE5687A);
}
