import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/language.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/itinerary.dart';
import '../../services/affiliate/stay22_service.dart';
import '../../utils/haptics.dart';
import '../webview/in_app_webview_screen.dart';

/// Ekvivalent RoadTripSection iz ResultView.swift — sada sa embedded mapom
/// (polyline + markeri po danu, isti bounds-fitting pattern kao
/// ExploreMapView/DayMapView) i akcijama po segmentu (Reserve overnight →
/// Stay22, Open in Google Maps).
class RoadTripSection extends StatelessWidget {
  const RoadTripSection({super.key, required this.trip});

  final RoadTripPlan trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: context.cardBackground, borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: context.textPrimary),
              const SizedBox(width: AppSpacing.sm),
              Text('Road trip', style: AppTypography.sectionTitle.copyWith(color: context.textPrimary)),
            ],
          ),
          if (trip.origin != null && trip.destination != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('${trip.origin} → ${trip.destination}', style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
          ],
          if (trip.totalDistanceKm != null && trip.totalDurationMin != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${trip.totalDistanceKm!.toStringAsFixed(1)} km · ${(trip.totalDurationMin! / 60).toStringAsFixed(1)} h total',
              style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          for (final day in trip.days) _dayCard(context, day),
        ],
      ),
    );
  }

  Widget _dayCard(BuildContext context, RoadTripDay day) {
    final title = day.title?.trim() ?? '';
    final subtitle = day.subtitle?.trim() ?? '';
    final segments = day.segments ?? const <DriveLeg>[];
    final mapPoints = _RoadTripMapPoint.fromDay(day);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.cardStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Day ${day.dayNumber}', style: AppTypography.cardTitle.copyWith(color: context.textPrimary)),
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(title, style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
            ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle, style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
            ),
          const SizedBox(height: AppSpacing.sm),
          if (mapPoints.length >= 2)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RoadTripDayMap(points: mapPoints),
            ),
          if (segments.isNotEmpty)
            for (final seg in segments) _segmentRow(context, seg)
          else
            Text('No segments available.', style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
        ],
      ),
    );
  }

  Widget _segmentRow(BuildContext context, DriveLeg seg) {
    final IconData icon;
    switch (seg.kind) {
      case DriveLegKind.drive:
        icon = Icons.directions_car_filled;
        break;
      case DriveLegKind.stop:
        icon = Icons.local_cafe_outlined;
        break;
      case DriveLegKind.overnight:
        icon = Icons.bed_outlined;
        break;
    }

    final label = seg.placeName ?? seg.label ?? '';
    final address = seg.address?.trim() ?? '';
    final hasCoords = seg.lat != null && seg.lon != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label ${_minutesToText(seg.minutes)}'.trim(),
                  style: AppTypography.body.copyWith(color: context.textPrimary),
                ),
                if (address.isNotEmpty)
                  Text(address, style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
              ],
            ),
          ),
          if (hasCoords && seg.kind == DriveLegKind.overnight) ...[
            const SizedBox(width: AppSpacing.sm),
            _SegmentActionButton(
              icon: Icons.bed_outlined,
              tooltip: 'Reserve overnight',
              onTap: () => _reserveOvernight(context, seg),
            ),
          ],
          if (hasCoords) ...[
            const SizedBox(width: AppSpacing.sm),
            _SegmentActionButton(
              icon: Icons.map_outlined,
              tooltip: 'Open in Google Maps',
              onTap: () => _openInGoogleMaps(seg.lat!, seg.lon!),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _reserveOvernight(BuildContext context, DriveLeg seg) async {
    Haptics.light();
    final url = Stay22Service.buildUrl(
      lat: seg.lat!,
      lon: seg.lon!,
      languageCode: kAppLanguageCode,
    );
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => InAppWebViewScreen(
          url: url,
          title: seg.placeName ?? 'Overnight stay',
        ),
      ),
    );
  }

  /// Android nema Apple Maps opciju — direktno Google Maps search URL.
  Future<void> _openInGoogleMaps(double lat, double lon) async {
    Haptics.light();
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _minutesToText(int m) {
    final h = m ~/ 60;
    final mm = m % 60;
    return h > 0 ? '${h}h${mm == 0 ? '' : ' ${mm}m'}' : '${mm}m';
  }
}

class _SegmentActionButton extends StatelessWidget {
  const _SegmentActionButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: context.accent.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: context.accent),
        ),
      ),
    );
  }
}

bool _isValidCoordinate(double? lat, double? lon) {
  if (lat == null || lon == null) return false;
  if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return false;
  if (lat.abs() < 0.0001 && lon.abs() < 0.0001) return false;
  return true;
}

/// Tačka na dnevnoj road trip mapi. `kind == null` označava start/end sidro
/// (morning/evening ItineraryItem koordinate iz planRoadTrip.ts), ne pravi
/// segment.
class _RoadTripMapPoint {
  const _RoadTripMapPoint({required this.kind, required this.label, required this.position});

  final DriveLegKind? kind;
  final String label;
  final LatLng position;

  /// Gradi uređenu listu tačaka za dnevnu mapu: start (morning coords) →
  /// stop/overnight segmenti (drive segmenti nemaju koordinate, preskaču se)
  /// → end (evening coords), OSIM kad dan već završava overnight segmentom
  /// (tada bi end bio duplikat istog mjesta).
  static List<_RoadTripMapPoint> fromDay(RoadTripDay day) {
    final points = <_RoadTripMapPoint>[];

    if (_isValidCoordinate(day.morning.lat, day.morning.lon)) {
      points.add(_RoadTripMapPoint(
        kind: null,
        label: day.morning.locationName ?? 'Start',
        position: LatLng(day.morning.lat!, day.morning.lon!),
      ));
    }

    final segments = day.segments ?? const <DriveLeg>[];
    for (final seg in segments) {
      if (seg.kind == DriveLegKind.drive) continue;
      if (!_isValidCoordinate(seg.lat, seg.lon)) continue;
      points.add(_RoadTripMapPoint(
        kind: seg.kind,
        label: seg.placeName ?? seg.label ?? '',
        position: LatLng(seg.lat!, seg.lon!),
      ));
    }

    final endsInOvernight = segments.isNotEmpty && segments.last.kind == DriveLegKind.overnight;
    if (!endsInOvernight && _isValidCoordinate(day.evening.lat, day.evening.lon)) {
      points.add(_RoadTripMapPoint(
        kind: null,
        label: day.evening.locationName ?? 'Destination',
        position: LatLng(day.evening.lat!, day.evening.lon!),
      ));
    }

    return points;
  }
}

/// GoogleMap za jedan road trip dan — polyline preko svih tačaka (aproksimacija
/// prave rute, jer planRoadTrip Cloud Function ne vraća punu encoded polyline
/// po danu, samo segment koordinate) + marker po tački, bounds-fit kamera
/// (isti pattern kao ExploreMapView/DayMapView).
class _RoadTripDayMap extends StatefulWidget {
  const _RoadTripDayMap({required this.points});

  final List<_RoadTripMapPoint> points;

  @override
  State<_RoadTripDayMap> createState() => _RoadTripDayMapState();
}

class _RoadTripDayMapState extends State<_RoadTripDayMap> {
  GoogleMapController? _controller;

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
  }

  Future<void> _fitCamera() async {
    final controller = _controller;
    if (controller == null || widget.points.isEmpty) return;

    if (widget.points.length == 1) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(widget.points.first.position, 12));
      return;
    }

    var minLat = widget.points.first.position.latitude;
    var maxLat = minLat;
    var minLon = widget.points.first.position.longitude;
    var maxLon = minLon;
    for (final p in widget.points.skip(1)) {
      minLat = math.min(minLat, p.position.latitude);
      maxLat = math.max(maxLat, p.position.latitude);
      minLon = math.min(minLon, p.position.longitude);
      maxLon = math.max(maxLon, p.position.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
  }

  double _hueFor(DriveLegKind? kind) {
    switch (kind) {
      case DriveLegKind.stop:
        return BitmapDescriptor.hueOrange;
      case DriveLegKind.overnight:
        return BitmapDescriptor.hueViolet;
      case DriveLegKind.drive:
      case null:
        return BitmapDescriptor.hueAzure;
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{
      for (var i = 0; i < widget.points.length; i++)
        Marker(
          markerId: MarkerId('point_$i'),
          position: widget.points[i].position,
          icon: BitmapDescriptor.defaultMarkerWithHue(_hueFor(widget.points[i].kind)),
          infoWindow: InfoWindow(title: widget.points[i].label),
        ),
    };

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('road_trip_day_route'),
        points: [for (final p in widget.points) p.position],
        color: context.accent,
        width: 3,
      ),
    };

    return SizedBox(
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: widget.points.first.position, zoom: 8),
          markers: markers,
          polylines: polylines,
          onMapCreated: _onMapCreated,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
        ),
      ),
    );
  }
}
