import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

/// Ekvivalent CLAuthorizationStatus (pojednostavljeno — Android/iOS preko
/// geolocator paketa nemaju identičan enum, pa mapiramo na najbliže).
enum DeviceLocationStatus {
  notDetermined,
  denied,
  deniedForever,
  authorizedWhenInUse,
  authorizedAlways,
}

/// Jednostavan lat/lon par (ekvivalent CLLocationCoordinate2D).
class LatLon {
  const LatLon(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

/// Ekvivalent DeviceLocationManager.swift.
///
/// Koristi `geolocator` (GPS pozicija + permission handling) i `geocoding`
/// (reverse geocoding za "Grad, Regija, Država" naziv) — DODAJ OBA PAKETA
/// u pubspec.yaml, trenutno ih nema:
///   geolocator: ^13.0.0
///   geocoding: ^3.0.0
///
/// Registruj kao ChangeNotifierProvider u providers/ sloju — ovo je
/// najbliži Flutter ekvivalent Swift-ovom ObservableObject sa @Published
/// poljima (za razliku od FirestoreService providera gdje sam namjerno
/// koristio StreamProvider, ovdje je 1:1 port prirodniji jer je ovo
/// dugotrajno stateful ponašanje, ne jednostavan data stream).
class DeviceLocationManager extends ChangeNotifier {
  DeviceLocationStatus status = DeviceLocationStatus.notDetermined;
  LatLon? currentCoordinate;
  double? horizontalAccuracyMeters;
  String? errorMessage;
  bool isRequesting = false;
  String? placemarkName;

  StreamSubscription<Position>? _positionSub;
  Timer? _timeoutTimer;
  Completer<LatLon?>? _pendingCompleter;
  double _targetAccuracyWanted = 150;
  String? _cachedPlacemarkName;

  /// Ekvivalent placemarkName(for:) — vraća "Grad, Regija, Država", keširano.
  Future<String?> placemarkForCoordinate(LatLon coord) async {
    if (_cachedPlacemarkName != null) return _cachedPlacemarkName;
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        coord.latitude,
        coord.longitude,
      );
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final name = [p.locality, p.administrativeArea, p.country]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');
      if (name.isNotEmpty) _cachedPlacemarkName = name;
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  /// Ekvivalent ensurePermissionAndFetch() — poziva se kad korisnik
  /// uključi "Koristi moju lokaciju".
  Future<void> ensurePermissionAndFetch() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      errorMessage = 'location_denied_message';
      notifyListeners();
      return;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    status = _mapPermission(permission);
    notifyListeners();

    switch (permission) {
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        await requestWarmStart();
        break;
      case LocationPermission.denied:
      case LocationPermission.deniedForever:
        errorMessage = 'location_denied_message';
        notifyListeners();
        break;
      case LocationPermission.unableToDetermine:
        break;
    }
  }

  DeviceLocationStatus _mapPermission(LocationPermission p) {
    switch (p) {
      case LocationPermission.always:
        return DeviceLocationStatus.authorizedAlways;
      case LocationPermission.whileInUse:
        return DeviceLocationStatus.authorizedWhenInUse;
      case LocationPermission.deniedForever:
        return DeviceLocationStatus.deniedForever;
      case LocationPermission.denied:
        return DeviceLocationStatus.denied;
      case LocationPermission.unableToDetermine:
        return DeviceLocationStatus.notDetermined;
    }
  }

  /// Ekvivalent oneShotCoordinate(timeout:targetAccuracy:) — čeka JEDNU
  /// dovoljno preciznu koordinatu ili nil na timeout/odbijanje.
  Future<LatLon?> oneShotCoordinate({
    Duration timeout = const Duration(seconds: 8),
    double targetAccuracy = 150,
  }) async {
    // Ako već imamo dobar fix, vrati odmah.
    final acc = horizontalAccuracyMeters;
    if (currentCoordinate != null && acc != null && acc > 0 && acc <= targetAccuracy) {
      return currentCoordinate;
    }

    await ensurePermissionAndFetch();
    _targetAccuracyWanted = targetAccuracy;

    return requestWarmStart(timeout: timeout, targetAccuracy: targetAccuracy);
  }

  /// Ekvivalent requestWarmStart(timeout:targetAccuracy:) — "zagrijava" GPS
  /// kratko, uzima najbolji fix, pa staje. Vraća Future da se može čekati
  /// (isto ponašanje kao Swift-ov CheckedContinuation).
  Future<LatLon?> requestWarmStart({
    Duration timeout = const Duration(seconds: 8),
    double targetAccuracy = 150,
  }) {
    isRequesting = true;
    errorMessage = null;
    currentCoordinate = null;
    horizontalAccuracyMeters = null;
    _targetAccuracyWanted = targetAccuracy;
    notifyListeners();

    _pendingCompleter?.complete(null);
    final completer = Completer<LatLon?>();
    _pendingCompleter = completer;

    _startUpdating(timeout: timeout);

    return completer.future;
  }

  void _startUpdating({required Duration timeout}) {
    _positionSub?.cancel();
    _timeoutTimer?.cancel();

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen(_onPosition, onError: _onError);

    _timeoutTimer = Timer(timeout, () {
      _positionSub?.cancel();
      _positionSub = null;
      _finish(currentCoordinate);
      if (currentCoordinate == null) {
        errorMessage = 'location_timeout_message';
        notifyListeners();
      }
    });
  }

  void _onPosition(Position position) {
    // Odbaci "stare" (>30s) ili vrlo grube (>2000m) fix-eve.
    final now = DateTime.now();
    final age = now.difference(position.timestamp);
    if (age.inSeconds > 30) return;
    if (position.accuracy <= 0 || position.accuracy > 2000) return;

    currentCoordinate = LatLon(position.latitude, position.longitude);
    horizontalAccuracyMeters = position.accuracy;
    notifyListeners();

    if (position.accuracy <= _targetAccuracyWanted) {
      _positionSub?.cancel();
      _positionSub = null;
      _timeoutTimer?.cancel();
      _timeoutTimer = null;

      unawaited(_updatePlacemark(currentCoordinate!));
      _finish(currentCoordinate);
    }
  }

  void _onError(Object error) {
    isRequesting = false;
    errorMessage = error.toString();
    notifyListeners();
    _positionSub?.cancel();
    _positionSub = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _finish(null);
  }

  Future<void> _updatePlacemark(LatLon coord) async {
    final name = await placemarkForCoordinate(coord);
    if (name != null) {
      placemarkName = name;
      notifyListeners();
    }
  }

  void _finish(LatLon? value) {
    isRequesting = false;
    notifyListeners();
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    final completer = _pendingCompleter;
    _pendingCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(value);
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }
}
