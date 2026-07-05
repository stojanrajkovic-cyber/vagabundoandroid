import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings/app_settings_store.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget — ekvivalent VagabundoApp.swift (App protocol + WindowGroup).
class VagabundoApp extends ConsumerWidget {
  const VagabundoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appThemeMode = ref.watch(appSettingsProvider).themeMode;

    return MaterialApp.router(
      title: 'Vagabundo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (appThemeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      routerConfig: router,
    );
  }
}
