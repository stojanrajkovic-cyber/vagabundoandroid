import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/interest.dart';
import '../services/interests/interests_service.dart';

/// Supabase kredencijali — čitaju se iz --dart-define, isto kao SUPABASE_URL
/// i SUPABASE_ANON_KEY koje README_FIREBASE.md pominje za iOS Info.plist.
///
/// Primjer pokretanja:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=<anon-key>
///
/// Nemoj hardkodirati ove vrijednosti u kod — to je isti razlog zašto smo
/// ranije uklonili google-services.json iz git-a.
const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

final interestsServiceProvider = Provider<InterestsService>((ref) {
  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL / SUPABASE_ANON_KEY nisu postavljeni. '
      'Pokreni sa --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
    );
  }

  final service = InterestsService(
    projectUrl: Uri.parse(_supabaseUrl),
    anonKey: _supabaseAnonKey,
  );

  ref.onDispose(service.dispose);
  return service;
});

/// Ekvivalent InterestsService.fetch(lang:) — keširano po jeziku dok se
/// provider ne invalidira (family po languageCode).
final interestsProvider = FutureProvider.family<List<Interest>, String>((ref, lang) {
  return ref.watch(interestsServiceProvider).fetch(lang: lang);
});

/// Ekvivalent InterestsService.fetchRandom(lang:limit:).
final randomInterestsProvider =
    FutureProvider.family<List<Interest>, ({String lang, int limit})>((ref, args) {
  return ref.watch(interestsServiceProvider).fetchRandom(lang: args.lang, limit: args.limit);
});
