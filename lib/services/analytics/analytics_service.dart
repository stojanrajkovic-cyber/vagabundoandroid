import 'package:firebase_analytics/firebase_analytics.dart';

/// Centralizovan wrapper oko FirebaseAnalytics-a. `firebase_analytics` paket
/// je u projektu od Faze 1, ali nikad nije stvarno pozivan — Play Console
/// Advertising ID deklaracija je postavljena na "Yes/Analytics", pa ovo mora
/// biti istinito.
///
/// SVAKI poziv je obavijen u try/catch — analytics NIKAD ne smije srušiti
/// app ili blokirati stvarnu funkcionalnost (npr. offline logEvent poziv).
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logPlanGenerated({
    required String country,
    required String city,
    required int days,
    required String tripPace,
    required bool byCar,
    required bool withKids,
  }) async {
    try {
      await _analytics.logEvent(name: 'plan_generated', parameters: {
        'country': country,
        'city': city,
        'days': days,
        'trip_pace': tripPace,
        'by_car': byCar ? 1 : 0,
        'with_kids': withKids ? 1 : 0,
      });
    } catch (e) {
      // ignore: avoid_print
      print('📊 AnalyticsService.logPlanGenerated failed: $e');
    }
  }

  Future<void> logRoadTripGenerated({
    required String origin,
    required String destination,
    required double totalDistanceKm,
  }) async {
    try {
      await _analytics.logEvent(name: 'road_trip_generated', parameters: {
        'origin': origin,
        'destination': destination,
        'total_distance_km': totalDistanceKm,
      });
    } catch (e) {
      // ignore: avoid_print
      print('📊 AnalyticsService.logRoadTripGenerated failed: $e');
    }
  }

  Future<void> logPlanShared() async {
    try {
      await _analytics.logEvent(name: 'plan_shared');
    } catch (e) {
      // ignore: avoid_print
      print('📊 AnalyticsService.logPlanShared failed: $e');
    }
  }

  /// Koristi Firebase-ov REZERVISAN 'sign_up' event (ugrađeni izvještaji).
  Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      // ignore: avoid_print
      print('📊 AnalyticsService.logSignUp failed: $e');
    }
  }

  /// Koristi Firebase-ov REZERVISAN 'login' event.
  Future<void> logLogin({required String method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      // ignore: avoid_print
      print('📊 AnalyticsService.logLogin failed: $e');
    }
  }

  Future<void> logExploreSearchPerformed({
    required String category,
    required int radiusMeters,
    required int resultsCount,
  }) async {
    try {
      await _analytics.logEvent(name: 'explore_search_performed', parameters: {
        'category': category,
        'radius': radiusMeters,
        'results_count': resultsCount,
      });
    } catch (e) {
      // ignore: avoid_print
      print('📊 AnalyticsService.logExploreSearchPerformed failed: $e');
    }
  }

  Future<void> logAccommodationBookingOpened({required String city}) async {
    try {
      await _analytics.logEvent(
        name: 'accommodation_booking_opened',
        parameters: {'city': city},
      );
    } catch (e) {
      // ignore: avoid_print
      print('📊 AnalyticsService.logAccommodationBookingOpened failed: $e');
    }
  }

  Future<void> logRentACarOpened({required String city}) async {
    try {
      await _analytics.logEvent(
        name: 'rent_a_car_opened',
        parameters: {'city': city},
      );
    } catch (e) {
      // ignore: avoid_print
      print('📊 AnalyticsService.logRentACarOpened failed: $e');
    }
  }

  Future<void> logPackingGuideGenerated({required int days}) async {
    try {
      await _analytics.logEvent(
        name: 'packing_guide_generated',
        parameters: {'days': days},
      );
    } catch (e) {
      // ignore: avoid_print
      print('📊 AnalyticsService.logPackingGuideGenerated failed: $e');
    }
  }

  /// User property (perzistentan atribut, ne jednokratan event) — postavi
  /// SVAKI PUT kad se tema promijeni (Settings) I jednom na app startup.
  Future<void> setThemePreference(String mode) async {
    try {
      await _analytics.setUserProperty(name: 'theme_preference', value: mode);
    } catch (e) {
      // ignore: avoid_print
      print('📊 AnalyticsService.setThemePreference failed: $e');
    }
  }
}
