import 'package:flutter/material.dart';

/// App theme for Jakki Tunisie.
///
/// Refined in Milestone 3 of `docs/PLAN.md` and re-tuned to match the
/// look of a traditional Tunisian wooden Mahbousseh board: dark green
/// felt, light-wood bezel, ornate white motifs on the spikes, and
/// wooden checkers.
class JakkiTheme {
  const JakkiTheme._();

  // Legacy accent tokens kept for non-board UI (banners, highlights).
  static const Color terracotta = Color(0xFFB94E3A);
  static const Color olive = Color(0xFF6E7B3A);
  static const Color parchment = Color(0xFFF4ECD8);
  static const Color charcoal = Color(0xFF2C2A26);

  // ----- Board tokens (wooden Tunisian board look) ---------------------
  /// Dark green felt cloth that covers the playing surface.
  static const Color feltGreen = Color(0xFF1F5C3D);
  static const Color feltGreenDeep = Color(0xFF153F2A);

  /// Light natural wood for the outer frame (oak / beech).
  static const Color woodLight = Color(0xFFD2B07A);
  static const Color woodMid = Color(0xFFB58A4E);
  static const Color woodDark = Color(0xFF7A5326);
  static const Color woodGrain = Color(0xFF6B4520);

  /// Aged-white paint used for the triangle outlines and motifs.
  static const Color motifWhite = Color(0xFFF1E6C8);

  /// Dark oxblood used for the "other" alternating triangle style.
  static const Color motifOxblood = Color(0xFF7A2B24);

  /// Hinge plate colour (brushed brass / iron).
  static const Color hingeMetal = Color(0xFF6F6962);
  static const Color hingeMetalLight = Color(0xFFB4A98E);

  // ----- Checker tokens (wooden discs) --------------------------------
  static const Color woodCheckerDark = Color(0xFF2A1709);
  static const Color woodCheckerDarkRim = Color(0xFF120800);
  static const Color woodCheckerCream = Color(0xFFE9D7A8);
  static const Color woodCheckerCreamRim = Color(0xFFA0855A);

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
