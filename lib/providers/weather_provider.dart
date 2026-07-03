import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/weather/weather_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) => WeatherService());

typedef WeatherCoordinates = ({double lat, double lon});

final weatherForecastProvider =
    FutureProvider.family<List<DayWeather>, WeatherCoordinates>((ref, coords) {
  return ref.watch(weatherServiceProvider).fetchForecast(lat: coords.lat, lon: coords.lon);
});
