import 'package:flutter/material.dart';

/// App theme for Jakki Tunisie.
///
/// Uses warm Tunisian-inspired tones: terracotta for the player accent,
/// olive green for the AI accent, and a parchment background. Refined
/// in Milestone 3 of `docs/PLAN.md`.
class JakkiTheme {
  const JakkiTheme._();

  static const Color terracotta = Color(0xFFB94E3A);
  static const Color olive = Color(0xFF6E7B3A);
  static const Color parchment = Color(0xFFF4ECD8);
  static const Color charcoal = Color(0xFF2C2A26);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: terracotta,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: parchment,
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: terracotta,
      brightness: Brightness.dark,
    );
    return ThemeData(useMaterial3: true, colorScheme: colorScheme);
  }
}
