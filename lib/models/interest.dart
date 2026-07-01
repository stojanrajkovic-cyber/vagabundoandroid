/// Ekvivalent Interest struct-a sa iOS-a.
///
/// NIJE PRONAĐEN u uploadanim fajlovima — sastavljen isključivo iz Supabase
/// REST upita u InterestsService.swift:
///   select=id,key,icon,sort_order,is_active,name_translations
/// Ako pravi Interest.swift ima dodatna polja (npr. lokalizovan naziv van
/// name_translations mape, ili drugi tip za id), javi pa uskladimo.
class Interest {
  const Interest({
    required this.id,
    required this.key,
    required this.icon,
    required this.sortOrder,
    required this.isActive,
    required this.nameTranslations,
  });

  final String id;
  final String key;
  final String icon;
  final int sortOrder;
  final bool isActive;

  /// Mapa jezik → naziv, npr. {"en": "Food", "bs": "Hrana"}.
  final Map<String, String> nameTranslations;

  /// Vraća prevod za dati jezik, sa fallback-om na 'en', pa na `key`.
  String localizedName(String languageCode) {
    return nameTranslations[languageCode] ?? nameTranslations['en'] ?? key;
  }

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['id'].toString(),
      key: json['key'] as String,
      icon: json['icon'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      nameTranslations: (json['name_translations'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'icon': icon,
        'sort_order': sortOrder,
        'is_active': isActive,
        'name_translations': nameTranslations,
      };
}
