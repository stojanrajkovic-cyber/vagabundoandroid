import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/nearby_poi.dart';
import '../models/poi_category.dart';
import '../services/functions/functions_service.dart';
import '../services/location/device_location_manager.dart';
import 'auth_provider.dart';
import 'location_provider.dart';

/// Port ExploreViewModel.swift state machine. `ExplorePurchasing` je
/// zadržan radi lakšeg re-wiring-a u Fazi 8 (RevenueCat) — trenutno se
/// nikad ne emituje jer je Explore besplatan na Androidu (nalog RevenueCat
/// još nije otvoren).
sealed class ExploreState {}

class ExploreIdle extends ExploreState {}

class ExploreRequestingLocation extends ExploreState {}

class ExploreLocationDenied extends ExploreState {}

class ExploreReady extends ExploreState {
  ExploreReady(this.coordinate);
  final LatLon coordinate;
}

class ExplorePurchasing extends ExploreState {} // TODO Faza 8: purchase gating

class ExploreLoading extends ExploreState {}

class ExploreLoaded extends ExploreState {
  ExploreLoaded(this.pois);
  final List<NearbyPOI> pois;
}

class ExploreEmpty extends ExploreState {}

class ExploreError extends ExploreState {
  ExploreError(this.message);
  final String message;
}

enum ExploreDisplayMode { list, map }

class ExploreController extends StateNotifier<ExploreState> {
  ExploreController(this.ref) : super(ExploreIdle());
  final Ref ref;

  bool get isCtaDisabled {
    final isAuthed = ref.read(isAuthenticatedProvider);
    if (!isAuthed) return true;
    if (state is! ExploreReady) return true;
    return false;
  }

  Future<void> start() async {
    state = ExploreRequestingLocation();
    final manager = ref.read(deviceLocationManagerProvider);
    final coord = await manager.oneShotCoordinate(
      timeout: const Duration(seconds: 8),
      targetAccuracy: 150,
    );

    if (coord == null) {
      final denied = manager.status == DeviceLocationStatus.denied ||
          manager.status == DeviceLocationStatus.deniedForever;
      state = denied
          ? ExploreLocationDenied()
          : ExploreError('Could not determine your location.');
      return;
    }
    state = ExploreReady(coord);
  }

  Future<void> explore(
      {required int radiusMeters, required Set<String> categoryKeys}) async {
    if (!ref.read(isAuthenticatedProvider)) return;
    final current = state;
    if (current is! ExploreReady) return;

    // TODO Faza 8: purchase gating ovdje (ExplorePurchasing state + RevenueCat
    // poziv preko PurchaseManager.exploreProduct()) prije nego se pređe na
    // loading — za sada Explore je besplatan na Androidu, preskačemo direktno.

    state = ExploreLoading();
    try {
      final googleTypes = PoiInterestMapper.mapToGoogleTypes(categoryKeys);
      final pois = await FunctionsService.instance.fetchNearbyPlaces(
        lat: current.coordinate.latitude,
        lon: current.coordinate.longitude,
        radiusMeters: radiusMeters,
        includedTypes: googleTypes,
      );
      state = pois.isEmpty ? ExploreEmpty() : ExploreLoaded(pois);
      // } catch (_) {
      //   state = ExploreError('Failed to load nearby places. Please try again.');
      // }
    } catch (e) {
      // ignore: avoid_print
      print('🔎 nearbyPlaces failed: $e');
      state = ExploreError('Failed to load nearby places. Please try again.');
    }
  }
}

final exploreControllerProvider =
    StateNotifierProvider<ExploreController, ExploreState>(
        (ref) => ExploreController(ref));
