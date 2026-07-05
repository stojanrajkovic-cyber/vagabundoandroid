import '../../models/itinerary.dart';
import '../../models/packing_guide.dart';
import '../weather/weather_service.dart';
import 'packing_recommendation_engine.dart';
import 'seasonal_weather_context.dart';

class PackingGeneratorService {
  PackingGeneratorService._();

  static Future<PackingGuide> generate({
    required ItineraryResponse itinerary,
    required DateTime startDate,
    required DateTime endDate,
    required double cityLat,
    required double cityLon,
    required WeatherService weatherService,
  }) async {
    final forecast =
        await weatherService.fetchForecast(lat: cityLat, lon: cityLon);
    final context = SeasonalWeatherContext.fromForecast(
      forecast: forecast,
      startDate: startDate,
      endDate: endDate,
    );

    print(itinerary.interests);

    final items = PackingRecommendationEngine.generateItems(
      itinerary: itinerary,
      context: context,
      pace: itinerary.pace,
      withKids: itinerary.withKids,
      interests: itinerary.interests ?? [],
    );

    // TODO: weather advice banner ako trip počinje uskoro i kiša je vjerovatna
    // (ekvivalent WeatherAdviceGenerator.adviceIfTripSoon — izvorni kod
    // nedostupan, preskočeno za sada).

    return PackingGuide(startDate: startDate, endDate: endDate, items: items);
  }
}
