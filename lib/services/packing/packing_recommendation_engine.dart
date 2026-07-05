import '../../models/itinerary.dart';
import '../../models/packing_guide.dart';
import 'seasonal_weather_context.dart';

/// 1:1 port PackingRecommendationEngine.swift — ista pravila, isti redoslijed,
/// ista dedup-by-key logika na kraju.
///
/// NAPOMENA o interesima: `ItineraryResponse.interests` čuva PUNE display
/// labele (npr. "Hiking", "Nightlife" — vidi selectedLabels() u
/// plan_config_provider.dart), NE kratke engleske key-eve kao iOS
/// ("hiking", "nature"). Nemamo pristup stvarnim Interest.key vrijednostima
/// iz Supabase tabele na ovom nivou, pa se poređenje radi case-insensitive
/// substring match-om nad display labelama — razumna fallback opcija koju
/// prompt eksplicitno dozvoljava. Ako se pokaže da labele ne sadrže očekivane
/// riječi (npr. zbog prevoda na jezik koji nije engleski), prilagodi listu
/// ključnih riječi ispod.
class PackingRecommendationEngine {
  PackingRecommendationEngine._();

  static List<PackingItem> generateItems({
    required ItineraryResponse itinerary,
    required SeasonalWeatherContext context,
    TripPace? pace,
    required bool withKids,
    List<String> interests = const [],
  }) {
    final items = <PackingItem>[];

    // Clothing
    items.add(PackingItem(category: PackingCategory.clothing, key: 'prep_underwear'));
    items.add(PackingItem(category: PackingCategory.clothing, key: 'prep_tshirts'));
    if (context.isCold) {
      items.add(PackingItem(category: PackingCategory.clothing, key: 'prep_warm_coat'));
      items.add(PackingItem(category: PackingCategory.clothing, key: 'prep_sweater'));
      items.add(PackingItem(category: PackingCategory.clothing, key: 'prep_gloves'));
      items.add(PackingItem(category: PackingCategory.clothing, key: 'prep_beanie'));
    }
    if (context.isHot) {
      items.add(PackingItem(category: PackingCategory.clothing, key: 'prep_light_clothes'));
      items.add(PackingItem(category: PackingCategory.clothing, key: 'prep_hat'));
      items.add(PackingItem(category: PackingCategory.clothing, key: 'prep_sunglasses'));
    }
    if (context.avgTemp > 22) {
      items.add(PackingItem(category: PackingCategory.clothing, key: 'prep_swimsuit'));
    }

    // Weather
    if (context.likelyRain) {
      items.add(PackingItem(category: PackingCategory.weather, key: 'prep_rain_jacket'));
      items.add(PackingItem(category: PackingCategory.weather, key: 'prep_umbrella'));
    }
    if (context.isHot) {
      items.add(PackingItem(category: PackingCategory.weather, key: 'prep_sunscreen'));
      items.add(PackingItem(category: PackingCategory.weather, key: 'prep_water_bottle'));
      items.add(PackingItem(category: PackingCategory.weather, key: 'prep_lip_balm'));
    }

    // Footwear
    items.add(PackingItem(category: PackingCategory.footwear, key: 'prep_comfortable_shoes'));
    if (context.avgTemp > 24) {
      items.add(PackingItem(category: PackingCategory.footwear, key: 'prep_flip_flops'));
    }
    if (context.likelyRain) {
      items.add(PackingItem(category: PackingCategory.footwear, key: 'prep_boots'));
    }

    // Documents
    items.add(PackingItem(category: PackingCategory.documents, key: 'prep_id_passport'));
    items.add(PackingItem(category: PackingCategory.documents, key: 'prep_tickets_reservations'));

    // Toiletries
    items.add(PackingItem(category: PackingCategory.toiletries, key: 'prep_toothbrush'));
    items.add(PackingItem(category: PackingCategory.toiletries, key: 'prep_basic_toiletries'));
    items.add(PackingItem(category: PackingCategory.toiletries, key: 'prep_hand_sanitizer'));

    // Tech
    items.add(PackingItem(category: PackingCategory.tech, key: 'prep_phone_charger'));
    items.add(PackingItem(category: PackingCategory.tech, key: 'prep_power_bank'));
    items.add(PackingItem(category: PackingCategory.tech, key: 'prep_travel_adapter'));
    items.add(PackingItem(category: PackingCategory.tech, key: 'prep_camera'));

    // Road trip
    if (itinerary.roadTrip != null) {
      items.add(PackingItem(category: PackingCategory.roadTrip, key: 'prep_car_charger'));
      items.add(PackingItem(category: PackingCategory.roadTrip, key: 'prep_snacks'));
      items.add(PackingItem(category: PackingCategory.roadTrip, key: 'prep_water_bottle'));
    }

    // Health
    if (pace == TripPace.packed) {
      items.add(PackingItem(category: PackingCategory.health, key: 'prep_blister_patches'));
    }
    items.add(PackingItem(category: PackingCategory.health, key: 'prep_basic_medicine'));

    // Kids
    if (withKids) {
      items.add(PackingItem(category: PackingCategory.kids, key: 'prep_kids_snacks'));
      items.add(PackingItem(category: PackingCategory.kids, key: 'prep_small_toys'));
      items.add(PackingItem(category: PackingCategory.kids, key: 'prep_wipes'));
    }

    // Interests (case-insensitive substring match — vidi napomenu iznad klase)
    if (_matchesAny(interests, ['hiking', 'nature'])) {
      items.add(PackingItem(category: PackingCategory.footwear, key: 'prep_hiking_shoes'));
      items.add(PackingItem(category: PackingCategory.weather, key: 'prep_daypack'));
    }
    if (_matchesAny(interests, ['beach'])) {
      items.add(PackingItem(category: PackingCategory.clothing, key: 'prep_swimwear'));
      items.add(PackingItem(category: PackingCategory.weather, key: 'prep_sunglasses'));
    }
    if (_matchesAny(interests, ['photography', 'photo'])) {
      items.add(PackingItem(category: PackingCategory.tech, key: 'prep_camera'));
      items.add(PackingItem(category: PackingCategory.tech, key: 'prep_extra_memory'));
    }
    if (_matchesAny(interests, ['museum', 'architecture'])) {
      items.add(PackingItem(category: PackingCategory.tech, key: 'prep_portable_charger'));
    }
    if (_matchesAny(interests, ['food'])) {
      items.add(PackingItem(category: PackingCategory.reminders, key: 'prep_food_reservations'));
    }
    if (_matchesAny(interests, ['nightlife'])) {
      items.add(PackingItem(category: PackingCategory.clothing, key: 'prep_evening_outfit'));
    }
    if (_matchesAny(interests, ['shopping'])) {
      items.add(PackingItem(category: PackingCategory.reminders, key: 'prep_extra_luggage'));
    }

    // Dedup by key
    final seen = <String>{};
    return items.where((i) => i.key == null || seen.add(i.key!)).toList();
  }

  static bool _matchesAny(List<String> interests, List<String> keywords) {
    return interests.any((interest) {
      final lower = interest.toLowerCase();
      return keywords.any((keyword) => lower.contains(keyword));
    });
  }
}
