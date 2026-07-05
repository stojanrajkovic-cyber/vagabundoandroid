import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

import '../../models/nearby_poi.dart';

class FunctionsService {
  FunctionsService._();
  static final FunctionsService instance = FunctionsService._();

  /// nearbyPlaces.ts vraća { pois: [...] } (potvrđeno iz izvornog koda) —
  /// ne sirov niz, otud ranija "not a subtype of List" greška.
  Future<List<NearbyPOI>> fetchNearbyPlaces({
    required double lat,
    required double lon,
    required int radiusMeters,
    List<String>? includedTypes,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('nearbyPlaces');
    final result = await callable.call<Map<String, dynamic>>({
      'lat': lat,
      'lon': lon,
      'radiusMeters': radiusMeters,
      if (includedTypes != null) 'includedTypes': includedTypes,
    });

    final rawList = result.data['pois'] as List<dynamic>? ?? [];

    return rawList
        .map((e) => NearbyPOI.fromMap(Map<String, dynamic>.from(e as Map)))
        .whereType<NearbyPOI>()
        .toList();
  }

  Future<Map<String, dynamic>> fetchPlaceDetails(String placeId) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('getPlaceDetails');
    final result =
        await callable.call<Map<String, dynamic>>({'placeId': placeId});
    return result.data;
  }

  Future<Uint8List> fetchPlacePhoto(String photoReference,
      {int maxWidth = 800}) async {
    final callable = FirebaseFunctions.instance.httpsCallable('getPlacePhoto');
    final result = await callable.call<Map<String, dynamic>>({
      'photoReference': photoReference,
      'maxWidth': maxWidth,
    });
    final base64Str = result.data['base64'] as String;
    return base64Decode(base64Str);
  }
}
