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
        seedColor: AppColors.accent,
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

/// Ekvivalent `AppTheme.Semantic.*` iz SwiftUI-a.
///
/// U SwiftUI-u je to bio static enum koji je automatski pratio
/// @Environment(\.colorScheme). Ovdje je to context-extenzija koja
/// radi isto — čita Theme.of(context).brightness.
///
/// Korištenje: `context.accent`, `context.cardStroke`, `context.textSecondary`
extension AppSemanticColors on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get accent => AppColors.accent;
  Color get cardBackground => _isDark ? AppColors.cardDark : AppColors.cardLight;
  Color get cardStroke => _isDark ? AppColors.cardStrokeDark : AppColors.cardStrokeLight;
  Color get textPrimary => _isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color get textSecondary => _isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
}
