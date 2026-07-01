import 'package:url_launcher/url_launcher.dart';

/// Ekvivalent NearbyPOI.swift.
class NearbyPOI {
  const NearbyPOI({
    required this.id,
    required this.placeId,
    required this.name,
    required this.category,
    required this.lat,
    required this.lon,
    required this.distanceMeters,
    this.isOpenNow,
  });

  final String id;
  final String placeId;
  final String name;
  final String category;
  final double lat;
  final double lon;
  final double distanceMeters;
  final bool? isOpenNow;

  /// Ekvivalent NearbyPOI.makeId(name:lat:lon:).
  static String makeId({required String name, required double lat, required double lon}) {
    return '${name.toLowerCase()}_${lat}_$lon';
  }

  /// Ekvivalent init?(from dict:) — vraća null ako fali obavezno polje.
  static NearbyPOI? fromMap(Map<String, dynamic> dict) {
    final placeId = dict['placeId'] as String?;
    final name = dict['name'] as String?;
    final category = dict['category'] as String?;
    final lat = (dict['lat'] as num?)?.toDouble();
    final lon = (dict['lon'] as num?)?.toDouble();
    final distanceMeters = dict['distanceMeters'] as int?;

    if (placeId == null ||
        name == null ||
        category == null ||
        lat == null ||
        lon == null ||
        distanceMeters == null) {
      return null;
    }

    return NearbyPOI(
      id: makeId(name: name, lat: lat, lon: lon),
      placeId: placeId,
      name: name,
      category: category,
      lat: lat,
      lon: lon,
      distanceMeters: distanceMeters.toDouble(),
      isOpenNow: dict['isOpenNow'] as bool?,
    );
  }

  /// Ekvivalent openInAppleMaps() — na Androidu nema Apple Maps, pa ovo
  /// otvara univerzalni geo: URI (Android sistemski mapa-picker).
  Future<void> openInMaps() async {
    final geoUri = Uri.parse('geo:$lat,$lon?q=$lat,$lon(${Uri.encodeComponent(name)})');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
      return;
    }
    await openInGoogleMaps();
  }

  /// Ekvivalent openInGoogleMaps() — probni comgooglemaps:// pa fallback na web.
  Future<void> openInGoogleMaps() async {
    final appUri = Uri.parse('comgooglemaps://?q=$lat,$lon');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
      return;
    }
    final webUri = Uri.parse('https://maps.google.com/?q=$lat,$lon');
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  @override
  bool operator ==(Object other) => other is NearbyPOI && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
