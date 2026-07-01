import 'package:flutter/services.dart';

/// Ekvivalent Haptics.light() / Haptics.swift s iOS-a.
class Haptics {
  Haptics._();

  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void selection() => HapticFeedback.selectionClick();
}
