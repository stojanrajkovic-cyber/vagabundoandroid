import 'package:flutter/material.dart';

/// Brand paleta boja.
///
/// PLACEHOLDER vrijednosti — kad uploadaš pravi AppTheme.swift,
/// zamijeni ove hex kodove s identičnim vrijednostima s iOS-a
/// da izgled bude 1:1.
class AppColors {
  AppColors._();

  static const Color accent = Color(0xFFFF6B4A);
  static const Color accentDark = Color(0xFFFF8A66);

  static const Color backgroundLight = Color(0xFFFAF9F7);
  static const Color backgroundDark = Color(0xFF141414);

  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1F1F1F);

  static const Color cardStrokeLight = Color(0x1A000000);
  static const Color cardStrokeDark = Color(0x33FFFFFF);

  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);

  static const Color textSecondaryLight = Color(0xFF6B6B6B);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);
}
