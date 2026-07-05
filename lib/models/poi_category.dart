import 'package:flutter/material.dart';

/// Port categoryIcon(for:) iz ExploreResultsView.swift — ikonica za POI
/// kategoriju vraćenu od `nearbyPlaces` Cloud Function-a.
class PoiCategoryIcons {
  PoiCategoryIcons._();

  static IconData iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
      case 'food':
        return Icons.restaurant;
      case 'cafe':
      case 'coffee':
        return Icons.local_cafe;
      case 'bar':
      case 'nightlife':
        return Icons.wine_bar;
      case 'fast_food':
      case 'fast food':
        return Icons.fastfood;
      case 'supermarket':
      case 'grocery':
        return Icons.shopping_cart;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'hospital':
      case 'clinic':
        return Icons.local_hospital;
      case 'atm':
      case 'bank':
        return Icons.attach_money;
      case 'parking':
        return Icons.local_parking;
      case 'fuel':
      case 'gas station':
        return Icons.local_gas_station;
      case 'ev_charger':
        return Icons.ev_station;
      case 'hotel':
      case 'accommodation':
        return Icons.hotel;
      case 'museum':
        return Icons.account_balance;
      case 'park':
      case 'garden':
        return Icons.park;
      case 'toilet':
      case 'public_toilet':
        return Icons.wc;
      case 'mobile_charger':
        return Icons.battery_charging_full;
      default:
        return Icons.place;
    }
  }
}

/// Explore POI filter kategorija — potpuno odvojena lista od Supabase
/// trip-interesa korištenih na Plan ekranu (vidi PlanConfigProvider).
class ExploreCategory {
  const ExploreCategory({required this.key, required this.label, required this.googleTypes});

  final String key; // interni ključ, ide u selectedKeys Set
  final String label; // UI prikaz
  final List<String> googleTypes; // Google Places v1 "includedTypes"
}

const List<ExploreCategory> kExploreCategories = [
  ExploreCategory(key: 'restaurant', label: 'Restaurants', googleTypes: ['restaurant']),
  ExploreCategory(key: 'cafe', label: 'Cafes', googleTypes: ['cafe']),
  ExploreCategory(key: 'bar', label: 'Bars', googleTypes: ['bar']),
  ExploreCategory(key: 'fast_food', label: 'Fast food', googleTypes: ['fast_food_restaurant']),
  ExploreCategory(key: 'supermarket', label: 'Supermarkets', googleTypes: ['supermarket']),
  ExploreCategory(key: 'pharmacy', label: 'Pharmacies', googleTypes: ['pharmacy']),
  ExploreCategory(key: 'atm', label: 'ATMs / Banks', googleTypes: ['atm', 'bank']),
  ExploreCategory(key: 'parking', label: 'Parking', googleTypes: ['parking']),
  ExploreCategory(key: 'gas_station', label: 'Gas stations', googleTypes: ['gas_station']),
  ExploreCategory(key: 'hotel', label: 'Hotels', googleTypes: ['lodging']),
  ExploreCategory(key: 'museum', label: 'Museums', googleTypes: ['museum']),
  ExploreCategory(key: 'park', label: 'Parks', googleTypes: ['park']),
];

class PoiInterestMapper {
  PoiInterestMapper._();

  /// Skupi sve Google Places type-ove za izabrane kategorije (union, bez
  /// duplikata). Vraća null ako je selekcija prazna — isto ponašanje kao
  /// Swift `includedTypes.isEmpty ? nil : includedTypes` (znači "sve kategorije").
  static List<String>? mapToGoogleTypes(Set<String> selectedKeys) {
    if (selectedKeys.isEmpty) return null;
    final types = <String>{};
    for (final cat in kExploreCategories) {
      if (selectedKeys.contains(cat.key)) types.addAll(cat.googleTypes);
    }
    return types.isEmpty ? null : types.toList();
  }
}
