import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Ekvivalent CityEntry.swift.
class CityEntry {
  const CityEntry({
    required this.name,
    required this.lat,
    required this.lon,
    this.stateCode,
    this.stateName,
  });

  final String name;
  final double lat;
  final double lon;

  /// Samo za SAD.
  final String? stateCode;
  final String? stateName;

  factory CityEntry.fromJson(Map<String, dynamic> json) {
    return CityEntry(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      stateCode: json['stateCode'] as String?,
      stateName: json['stateName'] as String?,
    );
  }
}

/// Ekvivalent CountryEntry.swift.
class CountryEntry {
  const CountryEntry({
    required this.code,
    required this.name,
    this.capital,
    this.population,
    this.currency,
    required this.cities,
  });

  final String code;
  final String name;
  final String? capital;
  final int? population;
  final String? currency;
  final List<CityEntry> cities;

  factory CountryEntry.fromJson(Map<String, dynamic> json) {
    final rawCities = json['cities'] as List<dynamic>? ?? const [];
    return CountryEntry(
      code: json['code'] as String,
      name: json['name'] as String,
      capital: json['capital'] as String?,
      population: json['population'] as int?,
      currency: json['currency'] as String?,
      cities: rawCities.map((e) => CityEntry.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Ekvivalent CountriesCitiesService.swift (bez Combine/@Published —
/// ovdje je čisti in-memory dataset, konzumira se preko
/// LocationSelectionProvider koji drži svoje Riverpod stanje).
///
/// Učitava assets/data/countries.json JEDNOM i keširano ga drži u memoriji
/// (244 države, ~32k gradova — dataset kopiran 1:1 iz iOS
/// Resources/Seed/CountriesCities.json).
class CountriesCitiesService {
  CountriesCitiesService._();

  static final CountriesCitiesService instance = CountriesCitiesService._();

  List<CountryEntry> _countries = const [];
  Future<void>? _loading;

  List<CountryEntry> get countries => _countries;

  /// Pozovi jednom (npr. u main() prije runApp, ili lazy prije prvog pristupa
  /// iz LocationSelectionProvider). Idempotentno — ponovni pozivi dok je
  /// učitavanje u toku dijele isti Future, i ne rade posao dvaput.
  Future<void> preload() {
    if (_countries.isNotEmpty) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/countries.json');
      final decoded = jsonDecode(raw) as List<dynamic>;
      final parsed = decoded
          .map((e) => CountryEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      _countries = parsed;
    } catch (_) {
      // Graceful empty-state (npr. mock/nepostojeći dataset) — ekran mora
      // da radi bez crash-a čak i bez countries.json.
      _countries = const [];
    } finally {
      _loading = null;
    }
  }
}
