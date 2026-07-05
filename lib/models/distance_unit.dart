/// Ekvivalent DistanceUnit + radius/distance formatting helpera sa iOS-a.
enum DistanceUnit { metric, imperial }

class RadiusOption {
  const RadiusOption({required this.meters, required this.label});
  final int meters;
  final String label;
}

class DistanceFormatter {
  DistanceFormatter._();

  static List<RadiusOption> radiusOptions(DistanceUnit unit) {
    if (unit == DistanceUnit.imperial) {
      return const [
        RadiusOption(meters: 800, label: '0.5 mi'),
        RadiusOption(meters: 1600, label: '1 mi'),
        RadiusOption(meters: 3200, label: '2 mi'),
        RadiusOption(meters: 8000, label: '5 mi'),
      ];
    }
    return const [
      RadiusOption(meters: 500, label: '500 m'),
      RadiusOption(meters: 1000, label: '1 km'),
      RadiusOption(meters: 2000, label: '2 km'),
      RadiusOption(meters: 5000, label: '5 km'),
    ];
  }

  /// Za prikaz distance do POI-ja u listi (ulaz je uvijek u metrima).
  static String formatDistance(double meters, DistanceUnit unit) {
    if (unit == DistanceUnit.imperial) {
      final miles = meters / 1609.34;
      // NAPOMENA: "ft" konverzija je gruba (meters*3.28), prihvatljivo za v1.
      return miles < 0.1 ? '${(meters * 3.28).round()} ft' : '${miles.toStringAsFixed(1)} mi';
    }
    return meters < 1000 ? '${meters.round()} m' : '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

/// Settings ekran ne postoji još (deferred) — default na metric bez
/// persistencije dok ta faza ne stigne.
/// TODO: pravo Settings polje kad se ta faza radi.
const DistanceUnit kDefaultDistanceUnit = DistanceUnit.metric;
