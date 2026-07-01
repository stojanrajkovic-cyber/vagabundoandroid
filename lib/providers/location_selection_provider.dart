import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/location/countries_cities_service.dart';

/// Ekvivalent City.swift (UI-strana modela, za razliku od "sirovog" CityEntry).
class City {
  const City({
    required this.name,
    required this.lat,
    required this.lon,
    this.stateCode,
    this.stateName,
  });

  final String name;
  final double lat;
  final double lon;
  final String? stateCode;
  final String? stateName;

  String get displayName => stateName != null ? '$name, $stateName' : name;
}

/// Ekvivalent Country.swift.
class Country {
  const Country({required this.code, required this.name, this.cities = const []});

  final String code;
  final String name;
  final List<City> cities;

  Country withCities(List<City> cities) => Country(code: code, name: name, cities: cities);
}

/// Ekvivalent USState.swift.
class USState {
  const USState({required this.code, required this.name});

  final String code;
  final String name;

  String get id => code;

  @override
  bool operator ==(Object other) => other is USState && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// Ekvivalent LocationViewModel.swift @Published stanja.
class LocationSelectionState {
  const LocationSelectionState({
    this.countries = const [],
    this.selectedCountry,
    this.selectedCity,
    this.isLoadingCities = false,
    this.citiesLoadError,
    this.selectedStateCode,
  });

  final List<Country> countries;
  final Country? selectedCountry;
  final City? selectedCity;
  final bool isLoadingCities;
  final String? citiesLoadError;
  final String? selectedStateCode;

  bool get isUSSelected => selectedCountry?.code == 'US';

  List<USState> get availableStates {
    final country = selectedCountry;
    if (!isUSSelected || country == null) return const [];

    final seen = <String>{};
    final states = <USState>[];
    for (final city in country.cities) {
      final code = city.stateCode;
      final name = city.stateName;
      if (code == null || name == null) continue;
      if (seen.add(code)) states.add(USState(code: code, name: name));
    }
    states.sort((a, b) => a.name.compareTo(b.name));
    return states;
  }

  List<City> get filteredCities {
    final country = selectedCountry;
    if (country == null) return const [];

    if (isUSSelected) {
      final state = selectedStateCode;
      if (state == null) return const [];
      return country.cities.where((c) => c.stateCode == state).toList();
    }
    return country.cities;
  }
}

/// Ekvivalent LocationViewModel.swift.
///
/// Pojednostavljeno u odnosu na iOS original: CountriesCitiesService već
/// drži SVE podatke u memoriji (nije network poziv), pa nema pravog razloga
/// za dvostepeno lijeno punjenje gradova. isLoadingCities i dalje postoji
/// (kratak async gap) da UI loading state ima smisla, ali logika je
/// jednostavnija nego DispatchQueue.global varijanta sa iOS-a.
class LocationSelectionNotifier extends StateNotifier<LocationSelectionState> {
  LocationSelectionNotifier() : super(const LocationSelectionState());

  Future<void> loadCountriesIfNeeded() async {
    if (state.countries.isNotEmpty) return;

    await CountriesCitiesService.instance.preload();
    final entries = CountriesCitiesService.instance.countries;

    state = LocationSelectionState(
      countries: entries.map((e) => Country(code: e.code, name: e.name)).toList(),
      selectedCountry: state.selectedCountry,
      selectedCity: state.selectedCity,
      isLoadingCities: state.isLoadingCities,
      citiesLoadError: state.citiesLoadError,
      selectedStateCode: state.selectedStateCode,
    );
  }

  Future<void> loadCitiesIfNeeded() async {
    final country = state.selectedCountry;
    if (country == null || country.cities.isNotEmpty) return;
    await selectCountry(country);
  }

  Future<void> selectCountry(Country country) async {
    state = LocationSelectionState(
      countries: state.countries,
      selectedCountry: country,
      selectedCity: null,
      isLoadingCities: state.isLoadingCities,
      citiesLoadError: null,
      selectedStateCode: null,
    );

    if (country.cities.isNotEmpty) return;

    state = LocationSelectionState(
      countries: state.countries,
      selectedCountry: state.selectedCountry,
      selectedCity: state.selectedCity,
      isLoadingCities: true,
      citiesLoadError: null,
      selectedStateCode: state.selectedStateCode,
    );

    try {
      // Dataset je već u memoriji — ovaj await postoji samo da loading state
      // ima priliku da se renderuje (isto ponašanje kao Swift DispatchQueue.global,
      // samo bez pravog pozadinskog thread-a jer nije potreban).
      await Future<void>.delayed(Duration.zero);

      CountryEntry? entry;
      for (final e in CountriesCitiesService.instance.countries) {
        if (e.code == country.code) {
          entry = e;
          break;
        }
      }

      final cities = (entry?.cities ?? const <CityEntry>[])
          .map((e) => City(
                name: e.name,
                lat: e.lat,
                lon: e.lon,
                stateCode: e.stateCode,
                stateName: e.stateName,
              ))
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));

      final updatedCountry = country.withCities(cities);
      final updatedCountries = [
        for (final c in state.countries) c.code == country.code ? updatedCountry : c,
      ];

      final stillSelected = state.selectedCountry?.code == country.code;
      state = LocationSelectionState(
        countries: updatedCountries,
        selectedCountry: stillSelected ? updatedCountry : state.selectedCountry,
        selectedCity: state.selectedCity,
        isLoadingCities: false,
        citiesLoadError: null,
        selectedStateCode: state.selectedStateCode,
      );
    } catch (e) {
      state = LocationSelectionState(
        countries: state.countries,
        selectedCountry: state.selectedCountry,
        selectedCity: state.selectedCity,
        isLoadingCities: false,
        citiesLoadError: e.toString(),
        selectedStateCode: state.selectedStateCode,
      );
    }
  }

  void selectState(String stateCode) {
    state = LocationSelectionState(
      countries: state.countries,
      selectedCountry: state.selectedCountry,
      selectedCity: null,
      isLoadingCities: state.isLoadingCities,
      citiesLoadError: state.citiesLoadError,
      selectedStateCode: stateCode,
    );
  }

  void selectCity(City city) {
    state = LocationSelectionState(
      countries: state.countries,
      selectedCountry: state.selectedCountry,
      selectedCity: city,
      isLoadingCities: state.isLoadingCities,
      citiesLoadError: state.citiesLoadError,
      selectedStateCode: state.selectedStateCode,
    );
  }

  /// Ekvivalent selectedCountryMetadata() — capital/population/currency za prikaz.
  CountryEntry? selectedCountryMetadata() {
    final code = state.selectedCountry?.code;
    if (code == null) return null;
    for (final e in CountriesCitiesService.instance.countries) {
      if (e.code == code) return e;
    }
    return null;
  }

  void resetCity() {
    state = LocationSelectionState(
      countries: state.countries,
      selectedCountry: state.selectedCountry,
      selectedCity: null,
      isLoadingCities: state.isLoadingCities,
      citiesLoadError: state.citiesLoadError,
      selectedStateCode: state.selectedStateCode,
    );
  }
}

final locationSelectionProvider =
    StateNotifierProvider<LocationSelectionNotifier, LocationSelectionState>((ref) {
  return LocationSelectionNotifier();
});
