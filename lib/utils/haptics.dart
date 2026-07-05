import 'package:flutter/services.dart';

/// Ekvivalent Haptics.light() / Haptics.swift s iOS-a.
class Haptics {
  Haptics._();

  /// Globalni toggle — ažuriran od AppSettingsController pri promjeni/pri
  /// app startu (vidi lib/services/settings/app_settings_store.dart).
  static bool enabled = true;

  static void light() { if (enabled) HapticFeedback.lightImpact(); }
  static void medium() { if (enabled) HapticFeedback.mediumImpact(); }
  static void heavy() { if (enabled) HapticFeedback.heavyImpact(); }
  static void selection() { if (enabled) HapticFeedback.selectionClick(); }
}
