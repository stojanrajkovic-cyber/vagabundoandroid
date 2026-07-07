import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/itinerary.dart';

/// Ekvivalent AppState.resolveIncomingShareIfNeeded() iz iOS-a — Faza B:
/// token (iz IncomingLinkService, Faza A) -> stvaran plan preko
/// publicPlans/{token} (piše ga createPublicPlanOnShare Cloud Function,
/// vidi functions/src/index.ts u iOS repo-u — potvrđeno da polje sa
/// itinerary sadržajem zove se `itineraryJSON`, isti pattern kao
/// plans/{planId}). Firestore rules: publicPlans je javno čitljiv
/// (allow read: if true), nema potrebe za autentifikacijom.
sealed class ShareResolveResult {}

class ShareResolveSuccess extends ShareResolveResult {
  ShareResolveSuccess(this.itinerary);
  final ItineraryResponse itinerary;
}

class ShareResolveNotFound extends ShareResolveResult {}

class ShareResolveInvalidData extends ShareResolveResult {}

class ShareLinkResolverService {
  ShareLinkResolverService._();

  static Future<ShareResolveResult> resolve(String token) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('publicPlans')
          .doc(token)
          .get();

      if (!doc.exists) return ShareResolveNotFound();

      final data = doc.data();
      if (data == null) return ShareResolveInvalidData();

      final itineraryJson = data['itineraryJSON'] as String?;
      if (itineraryJson == null) return ShareResolveInvalidData();

      final itinerary = ItineraryResponse.fromJsonString(itineraryJson);
      if (itinerary == null) return ShareResolveInvalidData();

      return ShareResolveSuccess(itinerary);
    } catch (e) {
      // ignore: avoid_print
      print('❌ ShareLinkResolverService.resolve error: $e');
      return ShareResolveInvalidData();
    }
  }
}
