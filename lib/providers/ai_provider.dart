import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai/itinerary_generator.dart';

/// Generator sada poziva sopstvenu Firebase Cloud Function ("generateItinerary")
/// umjesto AIProxy-ja direktno — vidi CloudItineraryGenerator u
/// itinerary_generator.dart. Region/projekat i auth se automatski uzimaju iz
/// `Firebase.initializeApp()` (main.dart), nema više potrebe za service
/// URL-om/partial key-em kao kod AIProxy-ja.
final itineraryGeneratorProvider = Provider<ItineraryGenerator>((ref) {
  return CloudItineraryGenerator();
});
