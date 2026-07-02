import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/itinerary.dart';
import '../../utils/haptics.dart';

/// Ekvivalent DayMapView.swift (bez MiniRoadMap/road trip logike — to je za
/// RoadTripSection). Prati isti "isValid" koordinatni check kao Swift, ali
/// PRESKAČE `LocationParser.parse(from:)` fallback (van obima za Fazu 4).
class DayMapView extends StatefulWidget {
  const DayMapView({
    super.key,
    required this.day,
    this.fallbackCenter,
    this.highlightedPart,
    this.isExpanded = false,
  });

  final ItineraryDay day;
  final LatLng? fallbackCenter;
  final DayPart? highlightedPart;
  final bool isExpanded;

  @override
  State<DayMapView> createState() => _DayMapViewState();
}

class _MapPoi {
  const _MapPoi({required this.part, required this.name, required this.position});

  final DayPart part;
  final String? name;
  final LatLng position;

  String get label {
    switch (part) {
      case DayPart.morning:
        return 'Morning';
      case DayPart.afternoon:
        return 'Afternoon';
      case DayPart.evening:
        return 'Evening';
    }
  }
}

bool _isValidCoordinate(double? lat, double? lon) {
  if (lat == null || lon == null) return false;
  if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return false;
  if (lat.abs() < 0.0001 && lon.abs() < 0.0001) return false;
  return true;
}

class _DayMapViewState extends State<DayMapView> {
  GoogleMapController? _controller;

  List<_MapPoi> get _pois {
    final entries = [
      (DayPart.morning, widget.day.morningItem),
      (DayPart.afternoon, widget.day.afternoonItem),
      (DayPart.evening, widget.day.eveningItem),
    ];
    return [
      for (final (part, item) in entries)
        if (_isValidCoordinate(item.lat, item.lon))
          _MapPoi(part: part, name: item.locationName, position: LatLng(item.lat!, item.lon!)),
    ];
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    // Fituje kameru odmah nakon prvog frame-a. Rebuild na promjenu
    // activeVariantIndex se rješava preko `key: ValueKey(day.activeVariantIndex)`
    // koji poziva roditelj (DayCard) — to forsira novi State (i novi
    // onMapCreated poziv) umjesto oslanjanja na didUpdateWidget, jer je
    // ItineraryDay mutable klasa pa bi oldWidget.day i widget.day bili
    // isti objekat (isto activeVariantIndex) u trenutku poređenja.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
  }

  Future<void> _fitCamera() async {
    final controller = _controller;
    if (controller == null) return;

    final pois = _pois;
    if (pois.isEmpty) {
      final fallback = widget.fallbackCenter;
      if (fallback != null) {
        await controller.animateCamera(CameraUpdate.newLatLngZoom(fallback, 12));
      }
      return;
    }

    if (pois.length == 1) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(pois.first.position, 14));
      return;
    }

    var minLat = pois.first.position.latitude;
    var maxLat = minLat;
    var minLon = pois.first.position.longitude;
    var maxLon = minLon;
    for (final poi in pois.skip(1)) {
      minLat = math.min(minLat, poi.position.latitude);
      maxLat = math.max(maxLat, poi.position.latitude);
      minLon = math.min(minLon, poi.position.longitude);
      maxLon = math.max(maxLon, poi.position.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
  }

  /// Ekvivalent NearbyPOI.openInMaps()/openInGoogleMaps() pattern-a
  /// (lib/models/nearby_poi.dart) — geo: URI pa Google Maps web fallback,
  /// BEZ Apple Maps/Google Maps picker dijaloga (Android nema Apple Maps).
  Future<void> _openInMaps(_MapPoi poi) async {
    final lat = poi.position.latitude;
    final lon = poi.position.longitude;
    final label = poi.name ?? poi.label;

    final geoUri = Uri.parse('geo:$lat,$lon?q=$lat,$lon(${Uri.encodeComponent(label)})');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
      return;
    }

    final appUri = Uri.parse('comgooglemaps://?q=$lat,$lon');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
      return;
    }

    final webUri = Uri.parse('https://maps.google.com/?q=$lat,$lon');
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  void _handleMapTap(LatLng _) {
    Haptics.light();
    final pois = _pois;
    if (pois.isEmpty) return;
    final highlighted = widget.highlightedPart;
    final target = highlighted != null
        ? pois.firstWhere((p) => p.part == highlighted, orElse: () => pois.first)
        : pois.first;
    _openInMaps(target);
  }

  @override
  Widget build(BuildContext context) {
    final pois = _pois;

    final markers = <Marker>{
      for (final poi in pois)
        Marker(
          markerId: MarkerId(poi.part.name),
          position: poi.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            poi.part == widget.highlightedPart ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(title: poi.name ?? poi.label, snippet: poi.label),
          onTap: () {
            Haptics.light();
            _openInMaps(poi);
          },
        ),
    };

    final polylines = <Polyline>{
      if (pois.length >= 2)
        Polyline(
          polylineId: const PolylineId('day_route'),
          points: [for (final p in pois) p.position],
          color: Colors.blue,
          width: 2,
        ),
    };

    final initialTarget = pois.isNotEmpty ? pois.first.position : (widget.fallbackCenter ?? const LatLng(0, 0));

    return SizedBox(
      height: widget.isExpanded ? MediaQuery.of(context).size.height : 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: initialTarget, zoom: 12),
          markers: markers,
          polylines: polylines,
          onMapCreated: _onMapCreated,
          onTap: _handleMapTap,
        ),
      ),
    );
  }
}
