import '../weather/weather_service.dart';

/// Namjerna izmjena u odnosu na iOS: umjesto sintetičke sezonske procjene
/// (SeasonalWeatherEstimator, izvorni kod nedostupan), koristi se STVARNA
/// Open-Meteo prognoza koju već imamo za WeatherCard — preciznije i besplatno
/// jer je poziv već keširan.
class SeasonalWeatherContext {
  const SeasonalWeatherContext({
    required this.avgTemp,
    required this.minTemp,
    required this.maxTemp,
    required this.likelyRain,
  });

  final double avgTemp;
  final double minTemp;
  final double maxTemp;
  final bool likelyRain;

  // Pragovi su PRETPOSTAVKA (nisam vidio originalne Swift vrijednosti) —
  // prilagodi ako se pokažu netačni u praksi.
  bool get isCold => avgTemp < 12;
  bool get isHot => avgTemp > 25;

  /// Gradi kontekst prosjekom Open-Meteo prognoze preko dana putovanja
  /// (startDate..endDate, ograničeno na ono što forecast pokriva — Open-Meteo
  /// ide do 16 dana unaprijed).
  factory SeasonalWeatherContext.fromForecast({
    required List<DayWeather> forecast,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final relevant = forecast.where((d) =>
        !d.date.isBefore(DateTime(startDate.year, startDate.month, startDate.day)) &&
        !d.date.isAfter(DateTime(endDate.year, endDate.month, endDate.day)));

    final days = relevant.isEmpty ? forecast : relevant.toList();
    if (days.isEmpty) {
      // Nema forecast podataka (npr. trip prevremen za 16-dnevni prozor) —
      // razuman globalni default umjesto crash-a.
      return const SeasonalWeatherContext(avgTemp: 20, minTemp: 14, maxTemp: 26, likelyRain: false);
    }

    final avgMax = days.map((d) => d.tempMaxC).reduce((a, b) => a + b) / days.length;
    final avgMin = days.map((d) => d.tempMinC).reduce((a, b) => a + b) / days.length;
    final maxRainProb = days.map((d) => d.precipitationProbability).reduce((a, b) => a > b ? a : b);

    return SeasonalWeatherContext(
      avgTemp: (avgMax + avgMin) / 2,
      minTemp: avgMin,
      maxTemp: avgMax,
      likelyRain: maxRainProb >= 50, // pretpostavljen prag, prilagodi po potrebi
    );
  }
}
