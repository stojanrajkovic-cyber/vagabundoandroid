import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/language.dart';
import '../models/interest.dart';
import '../models/itinerary.dart';
import '../services/interests/interests_service.dart';
import 'interests_provider.dart';

const String _customInterestsPrefsKey = 'plan_config_custom_interests_v1';

/// Ekvivalent PlanConfigViewModel.swift @Published stanja.
class PlanConfigState {
  const PlanConfigState({
    this.days = 2,
    this.withKids = false,
    this.allInterests = const [],
    this.selectedInterestKeys = const {},
    this.customInterestMap = const {},
    this.tripPace = TripPace.balanced,
    this.byCar = false,
    this.originQuery = '',
    this.useCurrentLocation = false,
    this.maxDrivingHoursPerDay = 5.0,
    this.breakEveryMinutes = 120,
    this.allowOvernightSplit = true,
  });

  final int days;
  final bool withKids;
  final List<Interest> allInterests;
  final Set<String> selectedInterestKeys;
  final Map<String, String> customInterestMap;
  final TripPace tripPace;

  final bool byCar;
  final String originQuery;
  final bool useCurrentLocation;
  final double maxDrivingHoursPerDay;
  final int breakEveryMinutes;
  final bool allowOvernightSplit;

  /// Sistemski interesi koji NISU selektovani (prikazani u "loaded" gridu).
  List<Interest> get loadedInterests =>
      allInterests.where((i) => !selectedInterestKeys.contains(i.key)).toList();

  /// Sistemski interesi koji JESU selektovani.
  List<Interest> get selectedSystemInterests =>
      allInterests.where((i) => selectedInterestKeys.contains(i.key)).toList();

  PlanConfigState copyWith({
    int? days,
    bool? withKids,
    List<Interest>? allInterests,
    Set<String>? selectedInterestKeys,
    Map<String, String>? customInterestMap,
    TripPace? tripPace,
    bool? byCar,
    String? originQuery,
    bool? useCurrentLocation,
    double? maxDrivingHoursPerDay,
    int? breakEveryMinutes,
    bool? allowOvernightSplit,
  }) {
    return PlanConfigState(
      days: days ?? this.days,
      withKids: withKids ?? this.withKids,
      allInterests: allInterests ?? this.allInterests,
      selectedInterestKeys: selectedInterestKeys ?? this.selectedInterestKeys,
      customInterestMap: customInterestMap ?? this.customInterestMap,
      tripPace: tripPace ?? this.tripPace,
      byCar: byCar ?? this.byCar,
      originQuery: originQuery ?? this.originQuery,
      useCurrentLocation: useCurrentLocation ?? this.useCurrentLocation,
      maxDrivingHoursPerDay: maxDrivingHoursPerDay ?? this.maxDrivingHoursPerDay,
      breakEveryMinutes: breakEveryMinutes ?? this.breakEveryMinutes,
      allowOvernightSplit: allowOvernightSplit ?? this.allowOvernightSplit,
    );
  }
}

/// Ekvivalent PlanConfigViewModel.swift.
class PlanConfigNotifier extends StateNotifier<PlanConfigState> {
  PlanConfigNotifier(this._ref) : super(const PlanConfigState()) {
    unawaited(_loadCustomInterestsFromPrefs());
  }

  final Ref _ref;

  /// Lijeno čita interestsServiceProvider (NE instancira novi servis) tek
  /// kad je stvarno potreban — ako se pozove eagerly (npr. direktno u
  /// StateNotifierProvider create funkciji), a SUPABASE_URL/ANON_KEY nisu
  /// postavljeni preko --dart-define, interestsServiceProvider baca
  /// StateError SINHRONO, što bi srušilo CIJELI MainScreen na svaki
  /// ref.watch(planConfigProvider). Odlaganjem pristupa i hvatanjem greške
  /// u loadInterestsIfNeeded/refreshRandomInterests, ekran ostaje
  /// koristan (custom interesi i dalje rade) čak i bez Supabase konfiguracije.
  InterestsServiceType get _interestsService => _ref.read(interestsServiceProvider);

  Future<void> _loadCustomInterestsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customInterestsPrefsKey);
    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final map = decoded.map((k, v) => MapEntry(k, v.toString()));
      state = state.copyWith(
        customInterestMap: map,
        selectedInterestKeys: {...state.selectedInterestKeys, ...map.keys},
      );
    } catch (_) {
      // Korumpiran/stari format — ignoriši, kreni od praznog stanja.
    }
  }

  Future<void> _persistCustomInterests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customInterestsPrefsKey, jsonEncode(state.customInterestMap));
  }

  Future<void> loadInterestsIfNeeded({int randomLimit = 12, String lang = kAppLanguageCode}) async {
    if (state.allInterests.isNotEmpty) return;
    try {
      final items = await _interestsService.fetchRandom(lang: lang, limit: randomLimit);
      state = state.copyWith(allInterests: items);
    } catch (_) {
      // Supabase nije konfigurisan (SUPABASE_URL/ANON_KEY) ili network greška —
      // ostavi allInterests prazno; ekran ostaje koristan (custom interesi rade).
    }
  }

  /// Ekvivalent refreshRandomInterests — zadržava selektovane sistemske
  /// interese, osvježava samo neselektovani pool.
  Future<void> refreshRandomInterests({int limit = 12, String lang = kAppLanguageCode}) async {
    try {
      final fresh = await _interestsService.fetchRandom(lang: lang, limit: limit);

      final keptSelected = state.allInterests
          .where((i) => state.selectedInterestKeys.contains(i.key))
          .toList();
      final keptKeys = keptSelected.map((i) => i.key).toSet();

      final newOnes = fresh.where((i) => !keptKeys.contains(i.key)).toList();

      state = state.copyWith(allInterests: [...keptSelected, ...newOnes]);
    } catch (_) {
      // Isto — graceful no-op umjesto propagacije greške u UI.
    }
  }

  void toggleInterest(String key) {
    final keys = {...state.selectedInterestKeys};
    if (!keys.add(key)) keys.remove(key);
    state = state.copyWith(selectedInterestKeys: keys);
  }

  Future<void> addCustomInterests(String input) async {
    final labels = input.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    if (labels.isEmpty) return;

    final newMap = {...state.customInterestMap};
    final newKeys = {...state.selectedInterestKeys};
    for (final label in labels) {
      final key = 'custom:${slugify(label)}';
      if (key == 'custom:') continue;
      newMap[key] = label;
      newKeys.add(key);
    }

    state = state.copyWith(customInterestMap: newMap, selectedInterestKeys: newKeys);
    await _persistCustomInterests();
  }

  Future<void> removeCustomInterest(String key) async {
    final newMap = {...state.customInterestMap}..remove(key);
    final newKeys = {...state.selectedInterestKeys}..remove(key);
    state = state.copyWith(customInterestMap: newMap, selectedInterestKeys: newKeys);
    await _persistCustomInterests();
  }

  /// Ekvivalent displayName(for:lang:) — custom mapa → allInterests lookup → fallback na key.
  String displayName(String key, String lang) {
    final custom = state.customInterestMap[key];
    if (custom != null) return custom;

    for (final interest in state.allInterests) {
      if (interest.key == key) return interest.localizedName(lang);
    }
    return key;
  }

  List<String> selectedLabels(String lang) {
    final labels = state.selectedInterestKeys.map((k) => displayName(k, lang)).toList();
    labels.sort();
    return labels;
  }

  void setDays(int days) => state = state.copyWith(days: days.clamp(1, 7));

  void setWithKids(bool value) => state = state.copyWith(withKids: value);

  void setTripPace(TripPace pace) => state = state.copyWith(tripPace: pace);

  void setByCar(bool value) => state = state.copyWith(byCar: value);

  void setOriginQuery(String value) => state = state.copyWith(originQuery: value);

  void setUseCurrentLocation(bool value) => state = state.copyWith(useCurrentLocation: value);

  void setMaxDrivingHoursPerDay(double value) =>
      state = state.copyWith(maxDrivingHoursPerDay: value.clamp(1.0, 12.0));

  void setBreakEveryMinutes(int value) =>
      state = state.copyWith(breakEveryMinutes: value.clamp(30, 240));

  void setAllowOvernightSplit(bool value) => state = state.copyWith(allowOvernightSplit: value);
}

final planConfigProvider = StateNotifierProvider<PlanConfigNotifier, PlanConfigState>((ref) {
  return PlanConfigNotifier(ref);
});

/// Ekvivalent Swift `slugify(_:)`: lowercase, ukloni dijakritike, razmaci → "-",
/// zadrži samo alfanumeričke i "-", kolabiraj "--" u "-".
///
/// NAPOMENA: ovo je osnovna (ASCII-transliteracijska) verzija, ne puna
/// Unicode-normalizacija — pokriva uobičajene latinične dijakritike i
/// bosansku/hrvatsku/srpsku abecedu (č,ć,š,đ,ž), što je dovoljno za slug-ove
/// generisane iz korisničkog unosa u ovoj app.
String slugify(String input) {
  final lower = input.toLowerCase().trim();
  final deaccented = _stripDiacritics(lower);
  final dashed = deaccented.replaceAll(RegExp(r'\s+'), '-');
  final cleaned = dashed.replaceAll(RegExp(r'[^a-z0-9\-]'), '');
  final collapsed = cleaned.replaceAll(RegExp(r'-{2,}'), '-');
  return collapsed.replaceAll(RegExp(r'^-+|-+$'), '');
}

const String _withDiacritics =
    'àáâãäåāòóôõöøōèéêëēìíîïīùúûüūñçÀÁÂÃÄÅĀÒÓÔÕÖØŌÈÉÊËĒÌÍÎÏĪÙÚÛÜŪÑÇšđčćžŠĐČĆŽ';
const String _withoutDiacritics =
    'aaaaaaaoooooooeeeeeiiiiiuuuuuncAAAAAAAOOOOOOOEEEEEIIIIIUUUUUNCsdcczSDCCZ';

String _stripDiacritics(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final idx = _withDiacritics.indexOf(char);
    buffer.write(idx >= 0 ? _withoutDiacritics[idx] : char);
  }
  return buffer.toString();
}
