import 'package:flutter/material.dart';

import 'colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.ochre,
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        foregroundColor:
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        elevation: 0,
      ),
    );
  }
}

/// Ekvivalent `AppTheme.Semantic.*` iz SwiftUI-a — čita boje ovisno o
/// trenutnom Brightness-u, isto kao @Environment(\.colorScheme) na iOS-u.
///
/// Korištenje: `context.accent`, `context.cardStroke`, `context.textSecondary`
extension AppSemanticColors on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  // Accent NIJE dynamic u Swift-u (uvijek ochre) — zadržano tako ovdje.
  Color get accent => AppColors.ochre;
  Color get onAccent => Colors.white;

  Color get cardBackground => _isDark ? AppColors.cardDark : AppColors.cardLight;
  Color get cardStroke => _isDark ? AppColors.cardStrokeDark : AppColors.cardStrokeLight;

  Color get textPrimary => _isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color get textSecondary => _isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  Color get blackWhite => _isDark ? Colors.white : Colors.black;

  Color get chipBackground => _isDark ? AppColors.chipBGDark : AppColors.chipBGLight;
  Color get chipText => _isDark ? AppColors.chipTextDark : AppColors.chipTextLight;
  Color get chipSelectedBackground =>
      _isDark ? AppColors.chipSelectedBGDark : AppColors.chipSelectedBGLight;
  Color get chipSelectedText =>
      _isDark ? AppColors.chipSelectedTextDark : AppColors.chipSelectedTextLight;

  Color get mapPinBackground => _isDark ? AppColors.mapPinBgDark : AppColors.mapPinBgLight;

  // Day selector (Faza 4 — DaySelector komponenta)
  Color get daySelectorUnselectedStroke => _isDark
      ? AppColors.daySelectorUnselectedStrokeDark
      : AppColors.daySelectorUnselectedStrokeLight;
  Color get daySelectorUnselectedText => _isDark
      ? AppColors.daySelectorUnselectedTextDark
      : AppColors.daySelectorUnselectedTextLight;
  Color get daySelectorUnselectedFill => _isDark
      ? AppColors.daySelectorUnselectedFillDark
      : AppColors.daySelectorUnselectedFillLight;
  Color get daySelectorSelectedStroke => _isDark
      ? AppColors.daySelectorSelectedStrokeDark
      : AppColors.daySelectorSelectedStrokeLight;
  Color get daySelectorSelectedText => _isDark
      ? AppColors.daySelectorSelectedTextDark
      : AppColors.daySelectorSelectedTextLight;
  Color get daySelectorSelectedFill => _isDark
      ? AppColors.daySelectorSelectedFillDark
      : AppColors.daySelectorSelectedFillLight;
}
