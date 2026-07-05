import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/itinerary.dart';
import '../services/profile/achievements_service.dart';
import 'firestore_provider.dart';

/// Ekvivalent ProfileStore.refreshPlans() — SA ISPRAVKOM: iOS original
/// računa `shouldHave` achievements ali nikad ne poziva persistenciju
/// (evaluateAchievements() postoji ali se ne poziva nigdje — mrtav kod/bug).
/// Ova verzija STVARNO snima nove achievements preko addAchievementsIfMissing.
class ProfileController {
  ProfileController(this.ref);
  final Ref ref;

  Future<ProfileDerivedStats> refresh() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const ProfileDerivedStats.empty();

    final plans = await ref.read(firestoreServiceProvider).fetchPlans(uid: uid);
    final completed = plans.where((p) => p.status == PlanStatus.completed).toList();

    double totalKm = 0;
    for (final plan in completed) {
      final itinerary = ItineraryResponse.fromJsonString(plan.itineraryJSON);
      final km = itinerary?.roadTrip?.totalDistanceKm;
      if (km != null) totalKm += km;
    }

    final currentProfile = await ref.read(userProfileProvider.future);
    final verifiedEmail = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    final shouldHave = AchievementsService.nextUnlocked(
      plansCount: plans.length,
      verifiedEmail: verifiedEmail,
    );

    // STVARNO snimi (fix) — koristi VEĆ POSTOJEĆU addAchievementsIfMissing.
    await ref.read(firestoreServiceProvider).addAchievementsIfMissing(
          uid: uid,
          have: currentProfile?.achievements ?? const [],
          shouldHave: shouldHave,
        );

    return ProfileDerivedStats(
      plansCount: plans.length,
      completedPlansCount: completed.length,
      totalKm: totalKm,
    );
  }
}

/// Derived stats — RAČUNATO iz `plans` niza (isto kao iOS refreshPlans()),
/// NE isto što i profile.stats.plansCount iz Firestore root dokumenta (koje
/// postoji iz drugih razloga, npr. monetizacije).
class ProfileDerivedStats {
  const ProfileDerivedStats({
    required this.plansCount,
    required this.completedPlansCount,
    required this.totalKm,
  });

  const ProfileDerivedStats.empty()
      : plansCount = 0,
        completedPlansCount = 0,
        totalKm = 0;

  final int plansCount;
  final int completedPlansCount;
  final double totalKm;
}

final profileControllerProvider = Provider<ProfileController>((ref) => ProfileController(ref));
