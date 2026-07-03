import 'dart:convert';

import 'package:http/http.dart' as http;

/// Ekvivalent WeatherKit dnevne prognoze sa iOS-a, portovano preko
/// Open-Meteo (besplatan REST API, bez API ključa — zamjena za Apple
/// Weather na Android-u, odluka iz originalnog plana).
class DayWeather {
  const DayWeather({
    required this.date,
    required this.weatherCode,
    required this.tempMaxC,
    required this.tempMinC,
    required this.feelsLikeMaxC,
    required this.precipitationProbability,
    required this.windSpeedKmh,
  });

  final DateTime date;

  /// WMO weather code — vidi lib/utils/weather_icons.dart za mapiranje.
  final int weatherCode;
  final double tempMaxC;
  final double tempMinC;
  final double feelsLikeMaxC;
  final int precipitationProbability;
  final double windSpeedKmh;
}

class WeatherService {
  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  final http.Client _client = http.Client();

  /// Vraća 16-dnevnu prognozu za date koordinate. Weather NIJE kritična
  /// funkcija — non-200 baca exception (poziva se hvata na strani providera
  /// preko FutureProvider AsyncValue), parse greška vraća [] umjesto da
  /// sruši ResultScreen.
  Future<List<DayWeather>> fetchForecast({required double lat, required double lon}) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,precipitation_probability_max,wind_speed_10m_max',
      'timezone': 'auto',
      'forecast_days': '16',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Open-Meteo request failed: HTTP ${response.statusCode}');
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final daily = decoded['daily'] as Map<String, dynamic>;

      final dates = (daily['time'] as List<dynamic>).cast<String>();
      final codes = (daily['weather_code'] as List<dynamic>).cast<num>();
      final tempMax = (daily['temperature_2m_max'] as List<dynamic>).cast<num>();
      final tempMin = (daily['temperature_2m_min'] as List<dynamic>).cast<num>();
      final feelsLikeMax = (daily['apparent_temperature_max'] as List<dynamic>).cast<num>();
      final precipProb = (daily['precipitation_probability_max'] as List<dynamic>).cast<num>();
      final windSpeed = (daily['wind_speed_10m_max'] as List<dynamic>).cast<num>();

      final count = dates.length;
      return [
        for (var i = 0; i < count; i++)
          DayWeather(
            date: DateTime.parse(dates[i]),
            weatherCode: codes[i].toInt(),
            tempMaxC: tempMax[i].toDouble(),
            tempMinC: tempMin[i].toDouble(),
            feelsLikeMaxC: feelsLikeMax[i].toDouble(),
            precipitationProbability: precipProb[i].toInt(),
            windSpeedKmh: windSpeed[i].toDouble(),
          ),
      ];
    } catch (_) {
      return [];
    }
  }
}
