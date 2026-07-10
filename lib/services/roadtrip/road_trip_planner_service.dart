import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';

import '../../models/itinerary.dart';

/// Poziva `planRoadTrip` Cloud Function (algoritamski Google Routes/Places
/// planer — vidi functions/src/planRoadTrip.ts) umjesto da AI izmišlja rutu.
class RoadTripPlannerService {
  RoadTripPlannerService._();
  static final RoadTripPlannerService instance = RoadTripPlannerService._();

  Future<RoadTripPlan?> plan({
    double? originLat,
    double? originLon,
    String? originName,
    required double destLat,
    required double destLon,
    required String destName,
    required double maxDrivingHoursPerDay,
    required int breakEveryMinutes,
    required String languageCode,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'planRoadTrip',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 115)),
      );
      final result = await callable.call<Map<String, dynamic>>({
        if (originLat != null) 'originLat': originLat,
        if (originLon != null) 'originLon': originLon,
        if (originName != null) 'originName': originName,
        'destLat': destLat,
        'destLon': destLon,
        'destName': destName,
        'maxDrivingHoursPerDay': maxDrivingHoursPerDay,
        'breakEveryMinutes': breakEveryMinutes,
        'languageCode': languageCode,
      });

      // Isti platform-channel gotcha kao nearbyPlaces/getPlaceDetails: ugniježđeni
      // Map/List-ovi u `result.data` dolaze kao Map<Object?, Object?> umjesto
      // Map<String, dynamic>, pa direktan `as Map<String, dynamic>` cast unutar
      // RoadTripDay/DriveLeg.fromJson puca. RoadTripPlan ima više nivoa
      // ugnježđenja (days[] -> segments[]/morning/afternoon/evening) pa
      // jednonivojski `Map<String, dynamic>.from()` nije dovoljan — round-trip
      // kroz JSON string garantuje ispravne tipove na svim nivoima odjednom.
      final normalized =
          jsonDecode(jsonEncode(result.data)) as Map<String, dynamic>;
      return RoadTripPlan.fromJson(normalized);
    } catch (e) {
      // ignore: avoid_print
      print('❌ RoadTripPlannerService.plan error: $e');
      return null; // pozivalac odlučuje fallback ponašanje
    }
  }
}
