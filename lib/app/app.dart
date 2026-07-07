import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/firestore/firestore_service.dart';
import '../services/settings/app_settings_store.dart';
import '../services/share/incoming_link_service.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget — ekvivalent VagabundoApp.swift (App protocol + WindowGroup).
class VagabundoApp extends ConsumerStatefulWidget {
  const VagabundoApp({super.key});

  @override
  ConsumerState<VagabundoApp> createState() => _VagabundoAppState();
}

class _VagabundoAppState extends ConsumerState<VagabundoApp> {
  late final IncomingLinkService _incomingLinkService;

  @override
  void initState() {
    super.initState();
    // Privremeno za Fazu A test — Faza B će ovo zamijeniti stvarnim
    // resolving-om (prikaz sadržaja na osnovu tokena).
    _incomingLinkService = IncomingLinkService((token) {
      // ignore: avoid_print
      print('✅ Faza A: token stigao do app-a: $token');
    });
    _incomingLinkService.start();
  }

  @override
  void dispose() {
    _incomingLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final appThemeMode = ref.watch(appSettingsProvider).themeMode;

    // FIX: ensureUserProfile() nikad nije bila zakačena nigdje u app-u —
    // Firestore users/{uid} dokument se NIKAD nije kreirao ni za jedan
    // sign-in metod (email/password, Google, obnovljena sesija). Ovo je
    // JEDINO mjesto koje treba — reaguje na SVAKU promjenu auth stanja,
    // bez obzira kako se korisnik ulogovao.
    ref.listen(authStateProvider, (previous, next) {
      final user = next.asData?.value;
      if (user != null) {
        FirestoreService.instance.ensureUserProfile(user);
      }
    });

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
