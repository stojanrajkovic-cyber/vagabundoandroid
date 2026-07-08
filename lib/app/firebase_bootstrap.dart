import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Future koji main() pokrene (Firebase.initializeApp()) i PROSLIJEDI ovdje
/// preko ProviderScope override-a — NIKAD se ne await-uje u main() prije
/// runApp()-a (to bi blokiralo prvi Flutter frame, pa nativni splash ostaje
/// "zamrznut" dok Firebase ne završi, umjesto da se odmah skine).
///
/// SplashScreen await-uje ovaj future PARALELNO sa svojom animacijom
/// (logo + typewriter tekst) — dok god animacija traje duže od Firebase
/// inita (obično tačno tako), korisnik nikad ne primijeti čekanje.
final firebaseInitProvider = Provider<Future<void>>((ref) {
  throw UnimplementedError(
    'firebaseInitProvider mora biti override-ovan u main() preko '
    'ProviderScope(overrides: [firebaseInitProvider.overrideWithValue(...)])',
  );
});
