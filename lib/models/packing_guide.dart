import '../services/packing/packing_item_labels.dart';

enum PackingCategory {
  clothing,
  footwear,
  weather,
  toiletries,
  tech,
  documents,
  health,
  roadTrip,
  kids,
  reminders;

  /// App je engleski-only (nema l10n) — direktan display label, ne lokalizacioni ključ.
  String get label {
    switch (this) {
      case PackingCategory.clothing:
        return 'Clothing';
      case PackingCategory.footwear:
        return 'Footwear';
      case PackingCategory.weather:
        return 'Weather';
      case PackingCategory.toiletries:
        return 'Toiletries';
      case PackingCategory.tech:
        return 'Tech';
      case PackingCategory.documents:
        return 'Documents';
      case PackingCategory.health:
        return 'Health';
      case PackingCategory.roadTrip:
        return 'Road trip';
      case PackingCategory.kids:
        return 'Kids';
      case PackingCategory.reminders:
        return 'Reminders';
    }
  }

  String toJson() => name;

  static PackingCategory fromJson(String raw) => PackingCategory.values
      .firstWhere((c) => c.name == raw, orElse: () => PackingCategory.reminders);
}

class PackingItem {
  PackingItem({
    String? id,
    required this.category,
    this.key,
    this.title,
    this.isCustom = false,
    this.isChecked = false,
  }) : id = id ?? _newId();

  final String id;
  final PackingCategory category;
  final String? key; // generisana stavka -> label ključ (vidi PackingItemLabels)
  final String? title; // custom stavka -> korisnikov tekst
  final bool isCustom;
  bool isChecked;

  static int _c = 0;
  static String _newId() => 'pack_${DateTime.now().microsecondsSinceEpoch}_${_c++}';

  /// Display tekst — custom stavka koristi title, generisana koristi englesku
  /// labelu za key.
  String displayText() => isCustom ? (title ?? '') : PackingItemLabels.labelFor(key ?? '');

  factory PackingItem.fromMap(Map<String, dynamic> m) => PackingItem(
        id: m['id'] as String,
        category: PackingCategory.fromJson(m['category'] as String),
        key: m['key'] as String?,
        title: m['title'] as String?,
        isCustom: m['isCustom'] as bool? ?? false,
        isChecked: m['isChecked'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category.toJson(),
        if (key != null) 'key': key,
        if (title != null) 'title': title,
        'isCustom': isCustom,
        'isChecked': isChecked,
      };
}

class PackingGuide {
  PackingGuide({
    String? id,
    required this.startDate,
    required this.endDate,
    required this.items,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? _newId(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final List<PackingItem> items;
  final String? notes;
  final DateTime createdAt;

  static int _c = 0;
  static String _newId() => 'guide_${DateTime.now().microsecondsSinceEpoch}_${_c++}';
}
