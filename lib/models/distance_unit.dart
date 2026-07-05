enum DistanceUnit { metric, imperial }

/// Jedinice se ne mogu mijenjati u UI-ju (isključena opcija, samo metrika je
/// u upotrebi — ista odluka kao na iOS-u). Kad/ako se Settings ekran napravi
/// i opcija se ponovo uključi, ovo postaje pravo korisničko podešavanje
/// (npr. preko shared_preferences) umjesto fiksne konstante.
const DistanceUnit kDefaultDistanceUnit = DistanceUnit.metric;

class RadiusOption {
  const RadiusOption({required this.meters, required this.label});
  final int meters;
  final String label;
}

class DistanceFormatter {
  DistanceFormatter._();

  /// NAPOMENA: jedinice se ne mogu mijenjati u UI-ju (isključena opcija i na
  /// iOS-u — samo metrika je u upotrebi). `imperial` grana je ostavljena
  /// namjerno (ne brisati kod), za slučaj da se ponovo uključi kasnije, ali
  /// se trenutno nikad ne poziva iz UI-ja.
  ///
  /// Vrijednosti usklađene sa STVARNIM iOS radius opcijama (500m/1km/2km/3km),
  /// i sa server-side clamp(100, 3000) u nearbyPlaces.ts — 3km je i gornja
  /// granica koju server prihvata, tako da UI opcije sad tačno odgovaraju
  /// onome što se stvarno primjenjuje.
  static List<RadiusOption> radiusOptions(DistanceUnit unit) {
    if (unit == DistanceUnit.imperial) {
      return const [
        RadiusOption(meters: 800, label: '0.5 mi'),
        RadiusOption(meters: 1600, label: '1 mi'),
        RadiusOption(meters: 3000, label: '~2 mi'),
      ];
    }
    return const [
      RadiusOption(meters: 500, label: '500 m'),
      RadiusOption(meters: 1000, label: '1 km'),
      RadiusOption(meters: 2000, label: '2 km'),
      RadiusOption(meters: 3000, label: '3 km'),
    ];
  }

  static String formatDistance(double meters, DistanceUnit unit) {
    if (unit == DistanceUnit.imperial) {
      final miles = meters / 1609.34;
      return miles < 0.1
          ? '${meters.round()} ft'
          : '${miles.toStringAsFixed(1)} mi';
    }
    return meters < 1000
        ? '${meters.round()} m'
        : '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
