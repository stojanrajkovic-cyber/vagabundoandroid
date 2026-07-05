import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

import '../../models/nearby_poi.dart';

/// Wrapper oko `nearbyPlaces`/`getPlaceDetails`/`getPlacePhoto` Cloud
/// Functions — iste funkcije koje su već u produkciji za iOS
/// (vidi ExploreViewModel.swift / FunctionsService.swift).
class FunctionsService {
  FunctionsService._();
  static final FunctionsService instance = FunctionsService._();

  Future<List<NearbyPOI>> fetchNearbyPlaces({
    required double lat,
    required double lon,
    required int radiusMeters,
    List<String>? includedTypes,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('nearbyPlaces');
    final result = await callable.call<List<dynamic>>({
      'lat': lat,
      'lon': lon,
      'radiusMeters': radiusMeters,
      if (includedTypes != null) 'includedTypes': includedTypes,
    });

    return result.data
        .map((e) => NearbyPOI.fromMap(Map<String, dynamic>.from(e as Map)))
        .whereType<NearbyPOI>()
        .toList();
  }

  /// `getPlaceDetails` response shape nije striktno poznat — pozivaoci
  /// (POIDetailSheet) treba da čitaju polja defenzivno (provjera tipa/null
  /// prije prikaza), ne pretpostavljaj striktnu šemu.
  Future<Map<String, dynamic>> fetchPlaceDetails(String placeId) async {
    final callable = FirebaseFunctions.instance.httpsCallable('getPlaceDetails');
    final result = await callable.call<Map<String, dynamic>>({'placeId': placeId});
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Vraća raw JPEG/PNG bytes (dekodiran iz base64 koji funkcija vrati).
  Future<Uint8List> fetchPlacePhoto(String photoReference, {int maxWidth = 800}) async {
    final callable = FirebaseFunctions.instance.httpsCallable('getPlacePhoto');
    final result = await callable.call<Map<String, dynamic>>({
      'photoReference': photoReference,
      'maxWidth': maxWidth,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final base64Str = data['base64'] as String;
    return base64Decode(base64Str);
  }
}
