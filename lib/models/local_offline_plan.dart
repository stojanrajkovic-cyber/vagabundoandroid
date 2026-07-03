import '../services/storage/local_plan_mirror.dart';
import 'itinerary.dart';

/// Ekvivalent LocalOfflinePlan sa iOS-a — jedan plan učitan direktno iz
/// [LocalPlanMirror] (bez Firestore metapodataka poput createdAt/status,
/// koji za offline mirror nisu čuvani zasebno — vidi loadAllOfflinePlans()).
class LocalOfflinePlan {
  const LocalOfflinePlan({required this.id, required this.itinerary});

  final String id;
  final ItineraryResponse itinerary;

  /// Ekvivalent LocalOfflinePlans.all() — učitava sve planove keširane na
  /// uređaju. Fajlovi koji ne mogu da se dekodiraju se preskaču (umjesto
  /// da sruše cijelu listu).
  static Future<List<LocalOfflinePlan>> loadAllOfflinePlans() async {
    final ids = await LocalPlanMirror.allPlanIds();
    final plans = <LocalOfflinePlan>[];
    for (final id in ids) {
      final itinerary = await LocalPlanMirror.load(id);
      if (itinerary != null) {
        plans.add(LocalOfflinePlan(id: id, itinerary: itinerary));
      }
    }
    return plans;
  }
}
