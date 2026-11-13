import 'package:flutter/material.dart';

/// Estilos tipográficos do aplicativo. A cor é aplicada pelo [UIText] conforme o tema.
TextStyle get appTitle => const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -.5);

TextStyle get caption => const TextStyle(fontSize: 9, letterSpacing: 1.8);

TextStyle get sectionTitle => const TextStyle(fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w700);

TextStyle get countdown => const TextStyle(fontSize: 38, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]);

TextStyle get countdownLabel => const TextStyle(fontSize: 10, letterSpacing: 1.5);

TextStyle get highlight => const TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

TextStyle get body => const TextStyle(fontSize: 14);

TextStyle get small => const TextStyle(fontSize: 12);

TextStyle get chartLabel => const TextStyle(fontSize: 9);

TextStyle get badge => const TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
