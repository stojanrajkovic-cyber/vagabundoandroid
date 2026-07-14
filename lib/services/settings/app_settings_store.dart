import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/haptics.dart';
import '../analytics/analytics_service.dart';

enum AppThemeMode { system, light, dark }

class AppSettingsState {
  const AppSettingsState({
    this.hapticsEnabled = true,
    this.soundEnabled = true,
    this.soundVolume = 0.8,
    this.themeMode = AppThemeMode.system,
  });

  final bool hapticsEnabled;
  final bool soundEnabled;
  final double soundVolume;
  final AppThemeMode themeMode;

  AppSettingsState copyWith({
    bool? hapticsEnabled,
    bool? soundEnabled,
    double? soundVolume,
    AppThemeMode? themeMode,
  }) {
    return AppSettingsState(
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Ekvivalent AppSettingsStore.swift — centralizovan, shared_preferences-backed.
class AppSettingsController extends StateNotifier<AppSettingsState> {
  AppSettingsController() : super(const AppSettingsState()) {
    _load();
  }

  static const _kHaptics = 'hapticsEnabled';
  static const _kSound = 'soundEnabled';
  static const _kVolume = 'soundVolume';
  static const _kTheme = 'themeMode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettingsState(
      hapticsEnabled: prefs.getBool(_kHaptics) ?? true,
      soundEnabled: prefs.getBool(_kSound) ?? true,
      soundVolume: prefs.getDouble(_kVolume) ?? 0.8,
      themeMode: AppThemeMode.values[prefs.getInt(_kTheme) ?? 0],
    );
    Haptics.enabled = state.hapticsEnabled;
  }

  Future<void> setHapticsEnabled(bool value) async {
    state = state.copyWith(hapticsEnabled: value);
    Haptics.enabled = value;
    (await SharedPreferences.getInstance()).setBool(_kHaptics, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    state = state.copyWith(soundEnabled: value);
    (await SharedPreferences.getInstance()).setBool(_kSound, value);
  }

  Future<void> setSoundVolume(double value) async {
    state = state.copyWith(soundVolume: value);
    (await SharedPreferences.getInstance()).setDouble(_kVolume, value);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    (await SharedPreferences.getInstance()).setInt(_kTheme, mode.index);
    AnalyticsService.instance.setThemePreference(mode.name);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsController, AppSettingsState>(
        (ref) => AppSettingsController());
