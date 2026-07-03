import 'itinerary.dart';

/// Ekvivalent PlanDocument (definisan u UserProfile.swift na iOS-u).
class PlanDocument {
  const PlanDocument({
    required this.id,
    required this.city,
    required this.days,
    required this.createdAt,
    required this.languageCode,
    required this.generatorModel,
    required this.itineraryJSON,
    this.cityLat,
    this.cityLon,
    this.status = PlanStatus.planned,
  });

  final String id;
  final String city;
  final int days;
  final DateTime createdAt;
  final String languageCode;
  final String generatorModel;
  final String itineraryJSON;
  final double? cityLat;
  final double? cityLon;
  final PlanStatus status;

  /// Ekvivalent Firestore decoding initializer-a (init?(id:dict:)).
  /// Vraća null ako nedostaje neko obavezno polje — isto ponašanje kao Swift.
  static PlanDocument? fromFirestore(String id, Map<String, dynamic> data) {
    final city = data['city'] as String?;
    final days = data['days'] as int?;
    final languageCode = data['languageCode'] as String?;
    final generatorModel = data['generatorModel'] as String?;
    final itineraryJSON = data['itineraryJSON'] as String?;

    if (city == null ||
        days == null ||
        languageCode == null ||
        generatorModel == null ||
        itineraryJSON == null) {
      return null;
    }

    // createdAt može biti Firestore Timestamp (iz snapshot-a) ili
    // epoch-seconds double (ako je već konvertovan u pozivaocu).
    DateTime createdAt;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else if (rawCreatedAt is num) {
      createdAt = DateTime.fromMillisecondsSinceEpoch((rawCreatedAt * 1000).round());
    } else {
      createdAt = DateTime.now();
    }

    return PlanDocument(
      id: id,
      city: city,
      days: days,
      createdAt: createdAt,
      languageCode: languageCode,
      generatorModel: generatorModel,
      itineraryJSON: itineraryJSON,
      cityLat: (data['cityLat'] as num?)?.toDouble(),
      cityLon: (data['cityLon'] as num?)?.toDouble(),
      status: PlanStatus.fromJson(data['status'] as String?),
    );
  }

  /// Ekvivalent lokalnog "creation" initializer-a — za novi plan prije
  /// snimanja u Firestore.
  factory PlanDocument.create({
    required String city,
    required int days,
    DateTime? createdAt,
    required String languageCode,
    required String generatorModel,
    required String itineraryJSON,
    double? cityLat,
    double? cityLon,
    PlanStatus status = PlanStatus.planned,
    String? id,
  }) {
    return PlanDocument(
      id: id ?? _newId(),
      city: city,
      days: days,
      createdAt: createdAt ?? DateTime.now(),
      languageCode: languageCode,
      generatorModel: generatorModel,
      itineraryJSON: itineraryJSON,
      cityLat: cityLat,
      cityLon: cityLon,
      status: status,
    );
  }

  static int _counter = 0;
  static String _newId() => 'plan_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
}

/// Ekvivalent VisitedCity (korišten u FirestoreService.swift, model nije
/// bio u posebnom fajlu — sastavljen iz upotrebe u FirestoreService.swift).
class VisitedCity {
  const VisitedCity({
    required this.id,
    required this.name,
    required this.country,
    required this.lat,
    required this.lon,
    required this.visitedAt,
    this.tripDistanceKm,
  });

  final String id;
  final String name;
  final String country;
  final double lat;
  final double lon;
  final DateTime visitedAt;
  final double? tripDistanceKm;
}

/// Ekvivalent UserStats.
class UserStats {
  UserStats({
    this.plansCount = 0,
    this.totalKm = 0,
    this.citiesCount = 0,
    this.freePlansRemaining = 0,
    this.completedPlans = 0,
    this.paidPlansCount = 0,
  });

  int plansCount;
  double totalKm;
  int citiesCount;
  int freePlansRemaining;
  int completedPlans;
  int paidPlansCount;

  factory UserStats.fromMap(Map<String, dynamic> dict) {
    return UserStats(
      plansCount: dict['plansCount'] as int? ?? 0,
      completedPlans: dict['completedPlans'] as int? ?? 0,
      totalKm: (dict['totalKm'] as num?)?.toDouble() ?? 0,
      citiesCount: dict['citiesCount'] as int? ?? 0,
      freePlansRemaining: dict['freePlansRemaining'] as int? ?? 0,
      paidPlansCount: dict['paidPlansCount'] as int? ?? 0,
    );
  }

  /// Ekvivalent travelerLevelKey iz Swift originala — trenutno se ne koristi,
  /// app je engleski-only (nema l10n sistema, namjerna odluka).
  String get travelerLevelKey {
    if (completedPlans == 0) return 'level_one_step';
    if (completedPlans < 5) return 'level_baby_footsteps';
    if (completedPlans < 15) return 'level_aspiring_traveler';
    if (completedPlans < 25) return 'level_experienced_explorer';
    if (completedPlans < 50) return 'level_citizen_world';
    return 'level_global_nomad';
  }

  /// 0...1 progres u trenutnom rangu.
  double get travelerLevelProgress {
    if (completedPlans < 1) return (completedPlans - 0) / 1.0;
    if (completedPlans < 5) return (completedPlans - 1) / 4.0;
    if (completedPlans < 15) return (completedPlans - 5) / 10.0;
    if (completedPlans < 25) return (completedPlans - 15) / 10.0;
    if (completedPlans < 50) return (completedPlans - 25) / 25.0;
    return 1.0;
  }

  /// Koliko putovanja fali do sljedećeg nivoa (null ako je max).
  int? get nextLevelRemaining {
    if (completedPlans < 1) return 1 - completedPlans;
    if (completedPlans < 5) return 5 - completedPlans;
    if (completedPlans < 15) return 15 - completedPlans;
    if (completedPlans < 25) return 25 - completedPlans;
    if (completedPlans < 50) return 50 - completedPlans;
    return null;
  }

  double get earthPercent => (totalKm / 40075.0 * 100.0).clamp(0, 100);
  double get moonPercent => (totalKm / 384400.0 * 100.0).clamp(0, 100);
  bool get usesEarthScale => totalKm < 40075.0;
}

/// Ekvivalent UserProfile.
class UserProfile {
  UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.createdAt,
    this.lastActive,
    UserStats? stats,
    this.achievements = const [],
  }) : stats = stats ?? UserStats();

  final String id;
  final String? displayName;
  final String? email;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final UserStats stats;
  final List<String> achievements;

  int get plansCount => stats.plansCount;

  /// Ekvivalent init?(id:dict:) — dict dolazi iz Firestore snapshot-a.
  ///
  /// NAPOMENA (bug prenesen iz iOS koda, dokumentovan namjerno): root
  /// dokument ima i `freePlansRemaining`/`paidPlansCount` na top-levelu
  /// (piše ih PurchaseManager) I nested `stats.freePlansRemaining` —
  /// ovaj initializer, kao i iOS original, favorizuje top-level vrijednost
  /// ako postoji (override nakon što se stats već parsira).
  static UserProfile? fromMap(String id, Map<String, dynamic> dict) {
    DateTime? parseEpoch(dynamic v) {
      if (v is num) return DateTime.fromMillisecondsSinceEpoch((v * 1000).round());
      return null;
    }

    final statsDict = dict['stats'] as Map<String, dynamic>?;
    final stats = statsDict != null ? UserStats.fromMap(statsDict) : UserStats();

    final freeRoot = dict['freePlansRemaining'] as int?;
    if (freeRoot != null) stats.freePlansRemaining = freeRoot;

    final paidRoot = dict['paidPlansCount'] as int?;
    if (paidRoot != null) stats.paidPlansCount = paidRoot;

    return UserProfile(
      id: id,
      displayName: dict['displayName'] as String?,
      email: dict['email'] as String?,
      createdAt: parseEpoch(dict['createdAt']),
      lastActive: parseEpoch(dict['lastActive']),
      stats: stats,
      achievements: (dict['achievements'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
