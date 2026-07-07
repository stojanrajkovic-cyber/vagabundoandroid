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

    final items = PackingRecommendationEngine.generateItems(
      itinerary: itinerary,
      context: context,
      pace: itinerary.pace,
      withKids: itinerary.withKids,
      interests: itinerary.interests ?? [],
    );

    // Ekvivalent WeatherAdviceGenerator.adviceIfTripSoon (izvorni Swift kod
    // nedostupan — ovo je razumna rekonstrukcija): upozori SAMO ako putovanje
    // počinje uskoro (unutar 3 dana od "danas" — ista Day1=danas pretpostavka
    // kao weather widget) I kiša je vjerovatna po istom kontekstu koji je
    // engine već izračunao.
    final daysUntilTrip = startDate.difference(DateTime.now()).inDays;
    final String? advice = (daysUntilTrip <= 3 && context.likelyRain)
        ? 'Rain is likely during your trip — pack a rain jacket or umbrella.'
        : null;

    return PackingGuide(
      startDate: startDate,
      endDate: endDate,
      items: items,
      notes: advice,
    );
  }
}
