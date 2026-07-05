import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/nearby_poi.dart';
import 'poi_detail_sheet.dart';

/// GoogleMap sa markerom po POI-ju, kamera fit-uje bounds preko svih POI-ja
/// (isti bounds-fitting pattern kao DayMapView.swift/day_map_view.dart iz
/// Faze 4). Tap na marker otvara POIDetailSheet.
class ExploreMapView extends StatefulWidget {
  const ExploreMapView({super.key, required this.pois});

  final List<NearbyPOI> pois;

  @override
  State<ExploreMapView> createState() => _ExploreMapViewState();
}

class _ExploreMapViewState extends State<ExploreMapView> {
  GoogleMapController? _controller;

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
  }

  Future<void> _fitCamera() async {
    final controller = _controller;
    if (controller == null || widget.pois.isEmpty) return;

    if (widget.pois.length == 1) {
      final poi = widget.pois.first;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(poi.lat, poi.lon), 14),
      );
      return;
    }

    var minLat = widget.pois.first.lat;
    var maxLat = minLat;
    var minLon = widget.pois.first.lon;
    var maxLon = minLon;
    for (final poi in widget.pois.skip(1)) {
      minLat = math.min(minLat, poi.lat);
      maxLat = math.max(maxLat, poi.lat);
      minLon = math.min(minLon, poi.lon);
      maxLon = math.max(maxLon, poi.lon);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
  }

  void _openDetails(NearbyPOI poi) {
    showPoiDetailSheet(context, poi);
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{
      for (final poi in widget.pois)
        Marker(
          markerId: MarkerId(poi.id),
          position: LatLng(poi.lat, poi.lon),
          infoWindow: InfoWindow(title: poi.name, snippet: poi.category),
          onTap: () => _openDetails(poi),
        ),
    };

    final initialTarget = widget.pois.isNotEmpty
        ? LatLng(widget.pois.first.lat, widget.pois.first.lon)
        : const LatLng(0, 0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: initialTarget, zoom: 13),
        markers: markers,
        onMapCreated: _onMapCreated,
      ),
    );
  }
}
