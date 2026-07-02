import 'dart:convert';

/// Ekvivalent Itinerary.swift.
///
/// NAPOMENA: `AIModel` enum nije uploadan (referenciran u iOS kodu kao
/// `AIModel.mini.rawValue`) — koristim string placeholder 'gpt-4o-mini'
/// dok ne vidimo pravi AIProxy/AIModel fajl. Zamijeni `kDefaultGeneratorModel`
/// kad taj fajl stigne.
const String kDefaultGeneratorModel = 'gpt-4o-mini';

/// Ekvivalent DaySegmentKey + DayPart (iOS ima dva skoro identična enuma sa
/// `.asDayPart` konverzijom) — u Dartu koristi se JEDAN enum svugdje.
/// Dart-ov `.name` već daje "morning"/"afternoon"/"evening", ekvivalent
/// Swift-ovog `.rawValue`.
enum DayPart {
  morning,
  afternoon,
  evening,
}

enum PlanStatus {
  planned,
  completed;

  static PlanStatus fromJson(String? raw) {
    return PlanStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => PlanStatus.planned,
    );
  }

  String toJson() => name;
}

enum TripPace {
  relaxed,
  balanced,
  packed;

  static TripPace? fromJson(String? raw) {
    if (raw == null) return null;
    for (final v in TripPace.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  String toJson() => name;

  /// Ekvivalent .localizedKey — koristi sa Flutter intl/l10n sistemom.
  String get localizationKey => 'trip_pace_$name';

  String get promptDescription {
    switch (this) {
      case TripPace.relaxed:
        return 'Fewer activities, slower rhythm, more breathing space.';
      case TripPace.balanced:
        return 'Moderate activity density with good pacing.';
      case TripPace.packed:
        return 'High activity density, efficient scheduling, minimal idle time.';
    }
  }
}

/// Ekvivalent ItinerarySelection enum (roadTrip / day(index)).
sealed class ItinerarySelection {
  const ItinerarySelection();
}

class RoadTripSelection extends ItinerarySelection {
  const RoadTripSelection();
}

class DaySelection extends ItinerarySelection {
  const DaySelection(this.index);
  final int index;
}

/// Ekvivalent PromptSnapshot (local-only debug/audit podatak).
class PromptSnapshot {
  const PromptSnapshot({
    required this.schemaVersion,
    required this.model,
    required this.createdAt,
    required this.languageCode,
    required this.systemPrompt,
    required this.userPrompt,
    this.requestFingerprint,
  });

  final int schemaVersion;
  final String model;
  final DateTime createdAt;
  final String languageCode;
  final String systemPrompt;
  final String userPrompt;
  final String? requestFingerprint;

  factory PromptSnapshot.fromJson(Map<String, dynamic> json) {
    return PromptSnapshot(
      schemaVersion: json['schemaVersion'] as int,
      model: json['model'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      languageCode: json['languageCode'] as String,
      systemPrompt: json['systemPrompt'] as String,
      userPrompt: json['userPrompt'] as String,
      requestFingerprint: json['requestFingerprint'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'model': model,
        'createdAt': createdAt.toIso8601String(),
        'languageCode': languageCode,
        'systemPrompt': systemPrompt,
        'userPrompt': userPrompt,
        if (requestFingerprint != null) 'requestFingerprint': requestFingerprint,
      };
}

/// Ekvivalent ItineraryItem.
///
/// Zadržava iste "resilient" decode fallback-ove kao Swift verzija:
/// locationName ⟵ locationName | location | place
/// lat/lon ⟵ lat/lon | latitude/longitude | nested gps{...}
/// (i lat/lon prihvataju i String i num u JSON-u, isto kao Swift.)
class ItineraryItem {
  const ItineraryItem({
    required this.title,
    required this.description,
    this.locationName,
    this.lat,
    this.lon,
  });

  final String title;
  final String description;
  final String? locationName;
  final double? lat;
  final double? lon;

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    final locationName = (json['locationName'] ?? json['location'] ?? json['place']) as String?;

    double? lat = _asDouble(json['lat']) ?? _asDouble(json['latitude']);
    double? lon = _asDouble(json['lon']) ?? _asDouble(json['longitude']);

    if ((lat == null || lon == null) && json['gps'] is Map) {
      final gps = json['gps'] as Map<String, dynamic>;
      lat ??= _asDouble(gps['lat']) ?? _asDouble(gps['latitude']);
      lon ??= _asDouble(gps['lon']) ?? _asDouble(gps['longitude']);
    }

    return ItineraryItem(
      title: json['title'] as String? ?? 'untitled',
      description: json['description'] as String? ?? '',
      locationName: locationName,
      lat: lat,
      lon: lon,
    );
  }

  /// Enkodira SAMO kanonske ključeve (isto kao Swift encode(to:)).
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        if (locationName != null) 'locationName': locationName,
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
      };
}

class DayBlock {
  DayBlock({required this.title, required this.steps}) : id = _uuid();

  final String id;
  final String title;
  final List<String> steps;

  static int _counter = 0;
  static String _uuid() => 'block_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  factory DayBlock.fromJson(Map<String, dynamic> json) {
    return DayBlock(
      title: json['title'] as String? ?? '',
      steps: (json['steps'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'steps': steps};
}

class DayStructure {
  const DayStructure({this.morning, this.afternoon, this.evening});

  final List<DayBlock>? morning;
  final List<DayBlock>? afternoon;
  final List<DayBlock>? evening;

  factory DayStructure.fromJson(Map<String, dynamic> json) {
    List<DayBlock>? parse(dynamic v) => (v as List<dynamic>?)
        ?.map((e) => DayBlock.fromJson(e as Map<String, dynamic>))
        .toList();

    return DayStructure(
      morning: parse(json['morning']),
      afternoon: parse(json['afternoon']),
      evening: parse(json['evening']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (morning != null) 'morning': morning!.map((e) => e.toJson()).toList(),
        if (afternoon != null) 'afternoon': afternoon!.map((e) => e.toJson()).toList(),
        if (evening != null) 'evening': evening!.map((e) => e.toJson()).toList(),
      };
}

class DayVariant {
  const DayVariant({
    required this.morning,
    required this.afternoon,
    required this.evening,
    this.dayStructure,
  });

  final ItineraryItem morning;
  final ItineraryItem afternoon;
  final ItineraryItem evening;
  final DayStructure? dayStructure;

  factory DayVariant.fromJson(Map<String, dynamic> json) {
    return DayVariant(
      morning: ItineraryItem.fromJson(json['morning'] as Map<String, dynamic>),
      afternoon: ItineraryItem.fromJson(json['afternoon'] as Map<String, dynamic>),
      evening: ItineraryItem.fromJson(json['evening'] as Map<String, dynamic>),
      dayStructure: json['dayStructure'] != null
          ? DayStructure.fromJson(json['dayStructure'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'morning': morning.toJson(),
        'afternoon': afternoon.toJson(),
        'evening': evening.toJson(),
        if (dayStructure != null) 'dayStructure': dayStructure!.toJson(),
      };
}

/// Ekvivalent ItineraryDay — podržava sva tri JSON formata koja podržava
/// i Swift (novi `variants[]`, stari `morningVariants/afternoonVariants/
/// eveningVariants`, i vrlo stari pojedinačni `morning/afternoon/evening`).
class ItineraryDay {
  ItineraryDay({
    required this.dayNumber,
    this.title,
    required this.variants,
    this.activeVariantIndex = 0,
  });

  final int dayNumber;
  final String? title;
  List<DayVariant> variants;
  int activeVariantIndex;

  int get id => dayNumber;

  DayVariant get activeVariant {
    if (activeVariantIndex < 0 || activeVariantIndex >= variants.length) {
      return variants.first;
    }
    return variants[activeVariantIndex];
  }

  ItineraryItem get morningItem => activeVariant.morning;
  ItineraryItem get afternoonItem => activeVariant.afternoon;
  ItineraryItem get eveningItem => activeVariant.evening;
  DayStructure? get dayStructure => activeVariant.dayStructure;

  bool get canAdvanceVariant => activeVariantIndex < variants.length - 1;

  void advanceVariant() {
    if (canAdvanceVariant) activeVariantIndex++;
  }

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    final dayNumber = json['dayNumber'] as int;
    final title = json['title'] as String?;

    // 🟢 NOVI FORMAT (variants array)
    final rawVariants = json['variants'] as List<dynamic>?;
    if (rawVariants != null && rawVariants.isNotEmpty) {
      return ItineraryDay(
        dayNumber: dayNumber,
        title: title,
        variants: rawVariants
            .map((e) => DayVariant.fromJson(e as Map<String, dynamic>))
            .toList(),
        activeVariantIndex: json['activeVariantIndex'] as int? ?? 0,
      );
    }

    // 🟡 STARI FORMAT (morningVariants/afternoonVariants/eveningVariants)
    final morningVariants = json['morningVariants'] as List<dynamic>?;
    final afternoonVariants = json['afternoonVariants'] as List<dynamic>?;
    final eveningVariants = json['eveningVariants'] as List<dynamic>?;

    if (morningVariants != null && afternoonVariants != null && eveningVariants != null) {
      final structure = json['dayStructure'] != null
          ? DayStructure.fromJson(json['dayStructure'] as Map<String, dynamic>)
          : null;

      final count = [morningVariants.length, afternoonVariants.length, eveningVariants.length]
          .reduce((a, b) => a < b ? a : b);

      final built = <DayVariant>[
        for (var i = 0; i < count; i++)
          DayVariant(
            morning: ItineraryItem.fromJson(morningVariants[i] as Map<String, dynamic>),
            afternoon: ItineraryItem.fromJson(afternoonVariants[i] as Map<String, dynamic>),
            evening: ItineraryItem.fromJson(eveningVariants[i] as Map<String, dynamic>),
            dayStructure: structure,
          ),
      ];

      return ItineraryDay(
        dayNumber: dayNumber,
        title: title,
        variants: built,
        activeVariantIndex: json['activeVariantIndex'] as int? ?? 0,
      );
    }

    // 🔵 VRLO STARI FORMAT (pojedinačni morning/afternoon/evening)
    final oldMorning = ItineraryItem.fromJson(json['morning'] as Map<String, dynamic>);
    final oldAfternoon = ItineraryItem.fromJson(json['afternoon'] as Map<String, dynamic>);
    final oldEvening = ItineraryItem.fromJson(json['evening'] as Map<String, dynamic>);

    return ItineraryDay(
      dayNumber: dayNumber,
      title: title,
      variants: [DayVariant(morning: oldMorning, afternoon: oldAfternoon, evening: oldEvening)],
      activeVariantIndex: json['activeVariantIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        if (title != null) 'title': title,
        'variants': variants.map((v) => v.toJson()).toList(),
        'activeVariantIndex': activeVariantIndex,
      };
}

class DriveLeg {
  DriveLeg({
    required this.kind,
    required this.minutes,
    this.label,
    this.headingTo,
    this.placeName,
    this.address,
    this.country,
    this.lat,
    this.lon,
  }) : id = _uuid();

  final String id;
  final DriveLegKind kind;
  final int minutes;
  final String? label;
  final String? headingTo;
  final String? placeName;
  final String? address;
  final String? country;
  final double? lat;
  final double? lon;

  static int _counter = 0;
  static String _uuid() => 'leg_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  factory DriveLeg.fromJson(Map<String, dynamic> json) {
    return DriveLeg(
      kind: DriveLegKind.fromJson(json['kind'] as String),
      minutes: json['minutes'] as int,
      label: json['label'] as String?,
      headingTo: json['headingTo'] as String?,
      placeName: json['placeName'] as String?,
      address: json['address'] as String?,
      country: json['country'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.toJson(),
        'minutes': minutes,
        if (label != null) 'label': label,
        if (headingTo != null) 'headingTo': headingTo,
        if (placeName != null) 'placeName': placeName,
        if (address != null) 'address': address,
        if (country != null) 'country': country,
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
      };
}

enum DriveLegKind {
  drive,
  stop,
  overnight;

  static DriveLegKind fromJson(String raw) =>
      DriveLegKind.values.firstWhere((e) => e.name == raw, orElse: () => DriveLegKind.drive);

  String toJson() => name;
}

class RoadTripDay {
  const RoadTripDay({
    required this.dayNumber,
    this.title,
    required this.morning,
    required this.afternoon,
    required this.evening,
    this.segments,
    this.subtitle,
  });

  final int dayNumber;
  final String? title;
  final ItineraryItem morning;
  final ItineraryItem afternoon;
  final ItineraryItem evening;
  final List<DriveLeg>? segments;
  final String? subtitle;

  int get id => dayNumber;

  factory RoadTripDay.fromJson(Map<String, dynamic> json) {
    return RoadTripDay(
      dayNumber: json['dayNumber'] as int,
      title: json['title'] as String?,
      morning: ItineraryItem.fromJson(json['morning'] as Map<String, dynamic>),
      afternoon: ItineraryItem.fromJson(json['afternoon'] as Map<String, dynamic>),
      evening: ItineraryItem.fromJson(json['evening'] as Map<String, dynamic>),
      segments: (json['segments'] as List<dynamic>?)
          ?.map((e) => DriveLeg.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtitle: json['subtitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        if (title != null) 'title': title,
        'morning': morning.toJson(),
        'afternoon': afternoon.toJson(),
        'evening': evening.toJson(),
        if (segments != null) 'segments': segments!.map((s) => s.toJson()).toList(),
        if (subtitle != null) 'subtitle': subtitle,
      };
}

class RoadTripPlan {
  const RoadTripPlan({
    this.origin,
    this.destination,
    this.totalDistanceKm,
    this.totalDurationMin,
    required this.days,
  });

  final String? origin;
  final String? destination;
  final double? totalDistanceKm;
  final double? totalDurationMin;
  final List<RoadTripDay> days;

  factory RoadTripPlan.fromJson(Map<String, dynamic> json) {
    return RoadTripPlan(
      origin: json['origin'] as String?,
      destination: json['destination'] as String?,
      totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble(),
      totalDurationMin: (json['totalDurationMin'] as num?)?.toDouble(),
      days: (json['days'] as List<dynamic>)
          .map((e) => RoadTripDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (origin != null) 'origin': origin,
        if (destination != null) 'destination': destination,
        if (totalDistanceKm != null) 'totalDistanceKm': totalDistanceKm,
        if (totalDurationMin != null) 'totalDurationMin': totalDurationMin,
        'days': days.map((d) => d.toJson()).toList(),
      };
}

/// Ekvivalent ItineraryRequest tipa — sastavljen iz upotrebe u
/// PromptBuilder.swift (nije postojao kao poseban uploadan fajl).
/// Polja su usklađena sa onim što PromptBuilder stvarno čita
/// (req.interests, req.tripPace, req.byCar, req.originName/Lat/Lon).
class ItineraryRequest {
  const ItineraryRequest({
    required this.country,
    required this.city,
    required this.languageCode,
    required this.model,
    this.days = 3,
    this.cityLat,
    this.cityLon,
    this.tripPace = TripPace.balanced,
    this.interests = const [],
    this.byCar = false,
    this.originName,
    this.originLat,
    this.originLon,
  });

  final String country;
  final String city;
  final String languageCode;
  final String model;
  final int days;
  final double? cityLat;
  final double? cityLon;
  final TripPace tripPace;
  final List<String> interests;

  /// Road trip način — kad je true, PromptBuilder dodaje car/roadTrip/origin addone.
  final bool byCar;
  final String? originName;
  final double? originLat;
  final double? originLon;
}

/// Ekvivalent ItineraryResponse (glavni model).
class ItineraryResponse {
  ItineraryResponse({
    required this.country,
    required this.city,
    required this.days,
    this.cityLat,
    this.cityLon,
    this.roadTrip,
    this.generatorModel = kDefaultGeneratorModel,
    this.promptSnapshot,
    this.status = PlanStatus.planned,
    this.completedAt,
    this.summary,
    this.pace,
    this.interests,
  }) : id = _uuid();

  final String id;
  final String country;
  final String city;
  final List<ItineraryDay> days;
  final double? cityLat;
  final double? cityLon;
  final RoadTripPlan? roadTrip;
  final String generatorModel;
  final PromptSnapshot? promptSnapshot;
  final PlanStatus status;
  final DateTime? completedAt;
  final String? summary;
  final TripPace? pace;
  final List<String>? interests;

  static int _counter = 0;
  static String _uuid() => 'itin_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  factory ItineraryResponse.fromJson(Map<String, dynamic> json) {
    return ItineraryResponse(
      country: json['country'] as String,
      city: json['city'] as String,
      days: (json['days'] as List<dynamic>)
          .map((e) => ItineraryDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      cityLat: (json['cityLat'] as num?)?.toDouble(),
      cityLon: (json['cityLon'] as num?)?.toDouble(),
      roadTrip: json['roadTrip'] != null
          ? RoadTripPlan.fromJson(json['roadTrip'] as Map<String, dynamic>)
          : null,
      generatorModel: json['generatorModel'] as String? ?? kDefaultGeneratorModel,
      promptSnapshot: json['promptSnapshot'] != null
          ? PromptSnapshot.fromJson(json['promptSnapshot'] as Map<String, dynamic>)
          : null,
      status: PlanStatus.fromJson(json['status'] as String?),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      summary: json['summary'] as String?,
      pace: TripPace.fromJson(json['pace'] as String?),
      interests: (json['interests'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// Parsira iz raw JSON string-a (ekvivalent ItineraryResponse.fromJSONString
  /// iz FirestoreService.swift ekstenzije).
  static ItineraryResponse? fromJsonString(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) return null;
      return ItineraryResponse.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'country': country,
        'city': city,
        'days': days.map((d) => d.toJson()).toList(),
        if (cityLat != null) 'cityLat': cityLat,
        if (cityLon != null) 'cityLon': cityLon,
        if (roadTrip != null) 'roadTrip': roadTrip!.toJson(),
        'generatorModel': generatorModel,
        'status': status.toJson(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        if (promptSnapshot != null) 'promptSnapshot': promptSnapshot!.toJson(),
        if (summary != null) 'summary': summary,
        if (pace != null) 'pace': pace!.toJson(),
        if (interests != null) 'interests': interests,
      };
}
