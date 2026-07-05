import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/plan_document.dart';

/// Journey map — marker po posjećenom gradu (userVisitsProvider), kamera
/// fit-uje bounds preko svih pinova. Isti bounds-fitting pattern kao
/// DayMapView/ExploreMapView.
class JourneyMapView extends StatefulWidget {
  const JourneyMapView({super.key, required this.visits});

  final List<VisitedCity> visits;

  @override
  State<JourneyMapView> createState() => _JourneyMapViewState();
}

class _JourneyMapViewState extends State<JourneyMapView> {
  GoogleMapController? _controller;

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
  }

  Future<void> _fitCamera() async {
    final controller = _controller;
    if (controller == null || widget.visits.isEmpty) return;

    if (widget.visits.length == 1) {
      final visit = widget.visits.first;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(visit.lat, visit.lon), 5),
      );
      return;
    }

    var minLat = widget.visits.first.lat;
    var maxLat = minLat;
    var minLon = widget.visits.first.lon;
    var maxLon = minLon;
    for (final visit in widget.visits.skip(1)) {
      minLat = math.min(minLat, visit.lat);
      maxLat = math.max(maxLat, visit.lat);
      minLon = math.min(minLon, visit.lon);
      maxLon = math.max(maxLon, visit.lon);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{
      for (final visit in widget.visits)
        Marker(
          markerId: MarkerId(visit.id),
          position: LatLng(visit.lat, visit.lon),
          infoWindow: InfoWindow(title: visit.name, snippet: visit.country),
        ),
    };

    final initialTarget = widget.visits.isNotEmpty
        ? LatLng(widget.visits.first.lat, widget.visits.first.lon)
        : const LatLng(20, 0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: initialTarget, zoom: 2),
        markers: markers,
        onMapCreated: _onMapCreated,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
      ),
    );
  }
}
