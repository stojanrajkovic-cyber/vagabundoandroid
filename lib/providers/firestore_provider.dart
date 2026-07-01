import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plan_document.dart';
import '../services/firestore/firestore_service.dart';
import 'auth_provider.dart';

/// Singleton FirestoreService — ekvivalent FirestoreService.shared.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService.instance;
});

/// NAPOMENA o dizajnu: umjesto da 1:1 portujem Swift-ov callback pattern
/// (startAppWideUserListeners(onProfile:onVisits:), ObservableObject-style),
/// koristim Riverpod StreamProvider direktno nad Firestore streamom.
///
/// Razlog: taj callback pattern je postojao da nahrani @Published property
/// na AppState (ObservableObject) — u Riverpod svijetu, StreamProvider
/// RADI tačno to (auto rebuild + auto dispose kad se widget skloni sa
/// stabla), bez potrebe za ručnim attach/detach listener management-om.
/// FirestoreService i dalje ima attachProfileListener/detachProfileListener
/// metode za slučajeve gdje ti eksplicitno treba callback-style API
/// (npr. izvan widget stabla), ali UI sloj bi trebao koristiti ove providere.

/// Ekvivalent @EnvironmentObject-ovanog profila korisnika — prati auth
/// stanje i automatski se re-subscribuje kad se korisnik promijeni.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.asData?.value?.uid;

  if (uid == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) {
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return UserProfile.fromMap(uid, data);
  });
});

/// Ekvivalent visits listenera (/users/{uid}/visits, sortirano najnovije prvo).
final userVisitsProvider = StreamProvider<List<VisitedCity>>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.asData?.value?.uid;

  if (uid == null) return Stream.value(const []);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('visits')
      .orderBy('visitedAt', descending: true)
      .snapshots()
      .map((qs) {
    // Napomena: parsing je duplikat _visitedCityFromMap iz FirestoreService
    // (ta metoda je privatna tamo). Ako želiš izbjeći duplikaciju, izvezi
    // je kao javnu static metodu u firestore_service.dart.
    return qs.docs
        .map((doc) {
          final d = doc.data();
          final name = d['name'] as String?;
          final country = d['country'] as String?;
          final lat = (d['lat'] as num?)?.toDouble();
          final lon = (d['lon'] as num?)?.toDouble();
          final ts = d['visitedAt'];
          if (name == null || country == null || lat == null || lon == null || ts == null) {
            return null;
          }
          return VisitedCity(
            id: doc.id,
            name: name,
            country: country,
            lat: lat,
            lon: lon,
            visitedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
            tripDistanceKm: (d['tripDistanceKm'] as num?)?.toDouble(),
          );
        })
        .whereType<VisitedCity>()
        .toList();
  });
});

/// Ekvivalent fetchPlans — lista planova trenutnog korisnika, najnoviji prvi.
final userPlansProvider = StreamProvider<List<PlanDocument>>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.asData?.value?.uid;

  if (uid == null) return Stream.value(const []);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('plans')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((qs) => qs.docs
          .map((doc) => PlanDocument.fromFirestore(doc.id, doc.data()))
          .whereType<PlanDocument>()
          .toList());
});

/// Ekvivalent fetchUserMonetization — one-shot fetch, ne stream (isto kao
/// iOS original koji se poziva u hydrateUserSession, ne kao live listener).
final userMonetizationProvider = FutureProvider<MonetizationSnapshot>((ref) async {
  final authState = ref.watch(authStateProvider);
  final uid = authState.asData?.value?.uid;

  if (uid == null) {
    return const MonetizationSnapshot(freePlansRemaining: 0, paidPlansCount: 0);
  }

  return ref.watch(firestoreServiceProvider).fetchUserMonetization(uid);
});
