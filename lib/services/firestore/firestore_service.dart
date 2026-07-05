import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../models/itinerary.dart';
import '../../models/packing_guide.dart';
import '../../models/plan_document.dart';

class MonetizationSnapshot {
  const MonetizationSnapshot({
    required this.freePlansRemaining,
    required this.paidPlansCount,
  });

  final int freePlansRemaining;
  final int paidPlansCount;
}

/// Ekvivalent FirestoreService.swift (singleton preko Riverpod providera,
/// vidi providers/firestore_provider.dart).
///
/// Bezbjednosne napomene (vezano za Firestore rules dogovorene ranije):
/// - `decrementFreePlans` i `consumeCredit`-ekvivalent koriste `runTransaction`
///   umjesto read-modify-write na klijentu, i mijenjaju vrijednost za tačno ±1 —
///   usklađeno sa `creditDeltaOk()`/`freePlansDeltaOk()` throttling pravilima.
/// - `updateFreePlans(value)` iz iOS koda (proizvoljna vrijednost bez provjere)
///   NIJE portovan — namjerno. To je bila glavna rupa; rules je sada blokiraju,
///   a ovdje je uklonjena i sama mogućnost da je kod pozove.
/// - FIX: `incrementFreePlansRemaining` u iOS kodu je pisao u nepostojeću
///   kolekciju `profiles` (bug) — ovdje ne postoji ekvivalent te funkcije,
///   logika je spojena u `redeemFreePlanReward` ispod, na ispravnoj kolekciji.
/// - FIX: `fetchUserMonetization` u iOS kodu je čitao `stats.plansCount`, a
///   `PurchaseManager` piše `paidPlansCount` (top-level) — ovdje čitamo
///   ispravno polje.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _plansCol(String uid) =>
      _userDoc(uid).collection('plans');

  CollectionReference<Map<String, dynamic>> _visitsCol(String uid) =>
      _userDoc(uid).collection('visits');

  StreamSubscription<fb_auth.User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _visitsSub;

  // MARK: - App-wide listeners

  /// Ekvivalent startAppWideUserListeners — prati auth stanje i re-veže
  /// profile/visits listenere kad se korisnik promijeni.
  void startAppWideUserListeners({
    required void Function(UserProfile?) onProfile,
    required void Function(List<VisitedCity>) onVisits,
  }) {
    if (_authSub != null) return; // već pokrenuto

    _authSub =
        fb_auth.FirebaseAuth.instance.authStateChanges().listen((user) async {
      await _profileSub?.cancel();
      _profileSub = null;
      await _visitsSub?.cancel();
      _visitsSub = null;

      if (user == null) {
        onProfile(null);
        onVisits(const []);
        return;
      }

      await ensureUserProfile(user);

      _profileSub = _userDoc(user.uid).snapshots().listen((snap) {
        final data = snap.data();
        if (data == null) {
          onProfile(null);
          return;
        }
        onProfile(UserProfile.fromMap(snap.id, data));
      });

      _visitsSub = _visitsCol(user.uid)
          .orderBy('visitedAt', descending: true)
          .snapshots()
          .listen((qs) {
        final items = qs.docs
            .map((doc) => _visitedCityFromMap(doc.id, doc.data()))
            .whereType<VisitedCity>()
            .toList();
        onVisits(items);
      });
    });
  }

  void stopAppWideUserListeners() {
    _authSub?.cancel();
    _authSub = null;
    _profileSub?.cancel();
    _profileSub = null;
    _visitsSub?.cancel();
    _visitsSub = null;
  }

  // MARK: - Profile lifecycle

  /// Ekvivalent ensureUserProfile(user:).
  Future<void> ensureUserProfile(fb_auth.User user) async {
    final ref = _userDoc(user.uid);
    try {
      final snap = await ref.get();

      if (snap.exists) {
        // Postojeći korisnik → NIKAD ne diraj freePlansRemaining ovdje.
        await ref.update({'lastActive': FieldValue.serverTimestamp()});
      } else {
        // Novi korisnik → device eligibility provjera je odgovornost
        // pozivaoca (ekvivalent FreePlanDeviceFlag na iOS-u, treba se
        // portovati u SharedPreferences kad dođemo do PurchaseManager faze).
        // Ovdje samo kreiramo profil sa 0 free planova po defaultu; UI sloj
        // treba proslijediti stvarnu vrijednost preko [initialFreePlans].
        await ref.set({
          'displayName': user.displayName,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'freePlansRemaining': 0,
          'stats': {'plansCount': 0, 'citiesCount': 0, 'totalKm': 0.0},
          'achievements': <String>[],
          'planCredits': <String, int>{}, // isto ponašanje kao iOS — vidi
          // fix objašnjenje za rules "Null value error" na potpuno odsutnom
          // planCredits polju.
          'paidPlansCount': 0,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // ignore: avoid_print
      print('ensureUserProfile error: $e');
    }
  }

  void attachProfileListener(String uid, void Function(UserProfile?) onChange) {
    _profileSub?.cancel();
    _profileSub = _userDoc(uid).snapshots().listen((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) {
        onChange(null);
        return;
      }
      onChange(UserProfile.fromMap(uid, data));
    });
  }

  void detachProfileListener() {
    _profileSub?.cancel();
    _profileSub = null;
  }

  // MARK: - Plans

  Future<void> savePlan(
      {required String uid, required PlanDocument plan}) async {
    final ref = _plansCol(uid).doc(plan.id);

    final payload = <String, dynamic>{
      'city': plan.city,
      'days': plan.days,
      'languageCode': plan.languageCode,
      'generatorModel': plan.generatorModel,
      'itineraryJSON': plan.itineraryJSON,
      'status': plan.status.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      if (plan.cityLat != null) 'cityLat': plan.cityLat,
      if (plan.cityLon != null) 'cityLon': plan.cityLon,
    };

    await ref.set(payload);
    // NAPOMENA: iOS verzija ovdje takođe piše u LocalPlanMirror (offline
    // cache) — to je predmet Faze 5 (Saved Plans / offline storage).
  }

  Future<List<PlanDocument>> fetchPlans(
      {required String uid, int limit = 50}) async {
    final qs = await _plansCol(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return qs.docs
        .map((doc) => PlanDocument.fromFirestore(doc.id, doc.data()))
        .whereType<PlanDocument>()
        .toList();
  }

  Future<void> deletePlan({required String uid, required String planId}) {
    return _plansCol(uid).doc(planId).delete();
  }

  Future<void> updatePlan({
    required String uid,
    required String planId,
    required Map<String, dynamic> fields,
  }) {
    return _plansCol(uid).doc(planId).update(fields);
  }

  Future<void> updatePlanStatus({
    required String uid,
    required String planId,
    required PlanStatus status,
  }) {
    return _plansCol(uid).doc(planId).update({
      'status': status.toJson(),
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // MARK: - Achievements

  Future<void> addAchievementsIfMissing({
    required String uid,
    required List<String> have,
    required List<String> shouldHave,
  }) async {
    final missing = shouldHave.where((s) => !have.contains(s)).toList();
    if (missing.isEmpty) return;
    try {
      await _userDoc(uid)
          .update({'achievements': FieldValue.arrayUnion(missing)});
    } catch (e) {
      // ignore: avoid_print
      print('achievements update error: $e');
    }
  }

  // MARK: - Visits / stats

  Future<List<VisitedCity>> fetchVisits(
      {required String uid, int limit = 50}) async {
    final qs = await _visitsCol(uid)
        .orderBy('visitedAt', descending: true)
        .limit(limit)
        .get();

    return qs.docs
        .map((doc) => _visitedCityFromMap(doc.id, doc.data()))
        .whereType<VisitedCity>()
        .toList();
  }

  VisitedCity? _visitedCityFromMap(String id, Map<String, dynamic> d) {
    final name = d['name'] as String?;
    final country = d['country'] as String?;
    final lat = (d['lat'] as num?)?.toDouble();
    final lon = (d['lon'] as num?)?.toDouble();
    final ts = d['visitedAt'];
    if (name == null ||
        country == null ||
        lat == null ||
        lon == null ||
        ts == null) {
      return null;
    }
    final visitedAt = ts is Timestamp ? ts.toDate() : DateTime.now();
    return VisitedCity(
      id: id,
      name: name,
      country: country,
      lat: lat,
      lon: lon,
      visitedAt: visitedAt,
      tripDistanceKm: (d['tripDistanceKm'] as num?)?.toDouble(),
    );
  }

  void attachVisitsListener(
      String uid, void Function(List<VisitedCity>) onChange) {
    _visitsSub?.cancel();
    _visitsSub = _visitsCol(uid)
        .orderBy('visitedAt', descending: true)
        .snapshots()
        .listen((qs) {
      final items = qs.docs
          .map((doc) => _visitedCityFromMap(doc.id, doc.data()))
          .whereType<VisitedCity>()
          .toList();
      onChange(items);
    });
  }

  void detachVisitsListener() {
    _visitsSub?.cancel();
    _visitsSub = null;
  }

  Future<void> addVisit(
      {required String uid, required VisitedCity city}) async {
    final payload = <String, dynamic>{
      'name': city.name,
      'country': city.country,
      'lat': city.lat,
      'lon': city.lon,
      'visitedAt': Timestamp.fromDate(city.visitedAt),
      if (city.tripDistanceKm != null) 'tripDistanceKm': city.tripDistanceKm,
    };
    await _visitsCol(uid).doc(city.id).set(payload, SetOptions(merge: true));
    await _incrementTotalsOnUserDoc(uid: uid, addKm: city.tripDistanceKm ?? 0);
  }

  Future<void> _incrementTotalsOnUserDoc(
      {required String uid, required double addKm}) async {
    final updates = <String, dynamic>{
      'lastActive': FieldValue.serverTimestamp(),
      'stats.citiesCount': FieldValue.increment(1),
    };
    if (addKm > 0) {
      updates['stats.totalKm'] = FieldValue.increment(addKm);
    }
    try {
      await _userDoc(uid).update(updates);
    } catch (e) {
      // ignore: avoid_print
      print('incrementTotalsOnUserDoc error: $e');
    }
  }

  Future<void> incrementCompletedPlans(String uid) async {
    try {
      await _userDoc(uid)
          .update({'completedPlansCount': FieldValue.increment(1)});
    } catch (e) {
      // ignore: avoid_print
      print('Failed to increment completedPlansCount: $e');
    }
  }

  // MARK: - Free plans (transakcijski, ±1 — usklađeno sa rules throttling-om)

  /// Ekvivalent decrementFreePlans(uid:) — transakcijski, vraća novu
  /// vrijednost, ne radi ništa ako je već 0.
  Future<int> decrementFreePlans(String uid) async {
    final ref = _userDoc(uid);
    var resultValue = 0;

    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final current = (snap.data()?['freePlansRemaining'] as int?) ?? 0;
      if (current <= 0) return;

      final newValue = current - 1;
      txn.update(ref, {'freePlansRemaining': newValue});
      resultValue = newValue;
    });

    return resultValue;
  }

  /// Ekvivalent nagrade "1 besplatan plan na svakih 10 plaćenih" iz
  /// PurchaseManager.consumeCredit — izdvojeno ovdje kao transakcija da
  /// bude atomično i da poštuje ±1 throttling iz rules-a.
  Future<void> redeemFreePlanRewardIfEarned(String uid) async {
    final ref = _userDoc(uid);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final data = snap.data() ?? {};
      final paidPlansCount = (data['paidPlansCount'] as int? ?? 0);
      if (paidPlansCount > 0 && paidPlansCount % 10 == 0) {
        final currentFree = (data['freePlansRemaining'] as int? ?? 0);
        txn.update(ref, {'freePlansRemaining': currentFree + 1});
      }
    });
  }

  Future<void> updateDisplayName(
      {required String uid, required String displayName}) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;

    try {
      await _userDoc(uid).update({'displayName': trimmed});

      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(trimmed);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to update displayName: $e');
    }
  }

  /// FIX: čita `paidPlansCount` (top-level, ono što PurchaseManager stvarno
  /// piše), ne `stats.plansCount` kao originalni iOS kod (koje se nikad
  /// ne ažurira — bio je bug).
  Future<MonetizationSnapshot> fetchUserMonetization(String uid) async {
    final snap = await _userDoc(uid).get();
    final data = snap.data() ?? {};

    final freePlans = data['freePlansRemaining'] as int? ?? 0;
    final paidPlans = data['paidPlansCount'] as int? ?? 0;

    return MonetizationSnapshot(
        freePlansRemaining: freePlans, paidPlansCount: paidPlans);
  }

  // MARK: - Packing Guide

  Future<void> savePackingGuide({
    required String uid,
    required String planId,
    required PackingGuide guide,
  }) async {
    final ref = _plansCol(uid).doc(planId).collection('packing').doc('guide');

    await ref.set({
      'id': guide.id,
      'startDate': Timestamp.fromDate(guide.startDate),
      'endDate': Timestamp.fromDate(guide.endDate),
      'items': guide.items.map((i) => i.toMap()).toList(),
      if (guide.notes != null) 'notes': guide.notes,
      'createdAt': Timestamp.fromDate(guide.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<PackingGuide?> loadPackingGuide(
      {required String uid, required String planId}) async {
    final ref = _plansCol(uid).doc(planId).collection('packing').doc('guide');
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return null;

    final startTs = data['startDate'];
    final endTs = data['endDate'];
    final createdTs = data['createdAt'];

    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => PackingItem.fromMap(e as Map<String, dynamic>))
        .toList();

    return PackingGuide(
      id: data['id'] as String?,
      startDate: startTs is Timestamp ? startTs.toDate() : DateTime.now(),
      endDate: endTs is Timestamp ? endTs.toDate() : DateTime.now(),
      items: items,
      notes: data['notes'] as String?,
      createdAt: createdTs is Timestamp ? createdTs.toDate() : DateTime.now(),
    );
  }
}

/// Ekvivalent ItineraryResponse.fromJSONString ekstenzije iz FirestoreService.swift.
/// (Sama parsing logika živi u models/itinerary.dart kao static metoda —
/// ovo je samo referenca za konzistentnost sa iOS strukturom fajla.)
ItineraryResponse? decodeItineraryJson(String json) =>
    ItineraryResponse.fromJsonString(json);
