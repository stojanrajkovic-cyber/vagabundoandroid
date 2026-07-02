import 'package:flutter/material.dart';

/// Prava brand paleta iz AppTheme.swift (Asset Catalog color imena →
/// hex vrijednosti iz komentara u Swift fajlu).
///
/// Ako se ovi hex kodovi pokažu netačni u poređenju sa Xcode Asset
/// Catalog-om (komentari u Swift-u mogu biti approximation), otvori
/// Assets.xcassets/Colors/*.colorset/Contents.json i uporedi.
class AppColors {
  AppColors._();

  // MARK: - Brand paleta (AppTheme.Colors u Swift-u)
  static const Color cerulean = Color(0xFF0075A2); // VagabundoCeruleanBlue
  static const Color alice = Color(0xFFEBF6FF); // VagabundoAliceBlue
  static const Color ochre = Color(0xFFDB7C26); // VagabundoOchre
  static const Color papaya = Color(0xFFFFECD1); // VagabundoPapayaWhip
  static const Color vandyke = Color(0xFF463730); // VagabundoVanDyke

  // MARK: - Nazivi zadržani radi kompatibilnosti sa ranije napisanim
  // Faza 1/2/3 kodom koji referencira AppColors.accent/.accentDark.
  static const Color accent = ochre;
  static const Color accentDark = Color(0xFFC26A1E); // tamnija ochre za gradient

  // Konkretne (non-dynamic) light/dark pozadinske boje — koristi se u
  // ThemeData._base() ispod, van BuildContext-a.
  static const Color backgroundLight = alice;
  static const Color backgroundDark = cerulean;

  // cardBackground iz Swift-a NIJE isto što i alice/cerulean — ima svoje
  // konkretne vrijednosti (vidi Semantic.cardBackground u AppTheme.swift).
  static const Color cardLight = Color(0xFFF7F6F0); // rgb(0.97, 0.965, 0.94)
  static const Color cardDark = Color(0xFF1C1C1E); // iOS secondarySystemBackground (dark)

  static Color cardStrokeLight = Colors.black.withValues(alpha: 0.05);
  static Color cardStrokeDark = Colors.white.withValues(alpha: 0.12);

  static const Color textPrimaryLight = cerulean;
  static const Color textPrimaryDark = alice;

  static Color textSecondaryLight = cerulean.withValues(alpha: 0.72);
  static Color textSecondaryDark = alice.withValues(alpha: 0.75);

  static const Color chipBGLight = papaya;
  static Color chipBGDark = alice.withValues(alpha: 0.18);

  static const Color chipTextLight = cerulean;
  static const Color chipTextDark = alice;

  static const Color chipSelectedBGLight = cerulean;
  static const Color chipSelectedBGDark = alice;

  static const Color chipSelectedTextLight = Colors.white;
  static const Color chipSelectedTextDark = cerulean;

  static const Color mapPinBgLight = Colors.grey;
  static const Color mapPinBgDark = alice;

  // Day selector (DaySelector komponenta, Faza 4)
  static const Color daySelectorUnselectedStrokeLight = cerulean;
  static const Color daySelectorUnselectedStrokeDark = Colors.white;
  static const Color daySelectorUnselectedTextLight = cerulean;
  static const Color daySelectorUnselectedTextDark = Colors.white;
  static const Color daySelectorUnselectedFillLight = Colors.white;
  static const Color daySelectorUnselectedFillDark = cerulean;
  static const Color daySelectorSelectedStrokeLight = Colors.white;
  static const Color daySelectorSelectedStrokeDark = cerulean;
  static const Color daySelectorSelectedTextLight = Colors.white;
  static const Color daySelectorSelectedTextDark = cerulean;
  static const Color daySelectorSelectedFillLight = cerulean;
  static const Color daySelectorSelectedFillDark = Colors.white;
}
