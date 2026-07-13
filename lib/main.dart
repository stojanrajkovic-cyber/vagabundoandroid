import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'services/ads/admob_service.dart';
// Generira se pomoću `flutterfire configure` (vidi README_FIREBASE.md)
// import 'firebase_options.dart';

/// NAPOMENA: Firebase.initializeApp() se NAMJERNO await-uje ovdje prije
/// runApp() — routerProvider (app/router.dart) čita authStateProvider ODMAH
/// pri prvom build-u (potrebno za redirect logiku), što interno poziva
/// FirebaseAuth.instance — a to PUCA ako Firebase.app() još ne postoji.
/// Ranija "ne čekaj, pusti splash da čeka paralelno" verzija je izazvala
/// baš ovu grešku (login prestao raditi) — vraćeno na jednostavno i
/// sigurno: čekaj, pa tek onda pokreni bilo šta od widget stabla.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
      );

  await AdMobService.instance.initialize();

  runApp(const ProviderScope(child: VagabundoApp()));
}
