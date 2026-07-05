/// Ekvivalent AchievementsService.swift.
class AchievementsService {
  AchievementsService._();

  /// Sve achievement key-eve koje korisnik TREBA imati na osnovu trenutnih
  /// statistika (isti pragovi kao iOS: 1/5/10 planova, verifikovan email).
  static List<String> nextUnlocked({
    required int plansCount,
    required bool verifiedEmail,
  }) {
    final result = <String>[];
    if (plansCount >= 1) result.add('firstPlan');
    if (plansCount >= 5) result.add('fivePlans');
    if (plansCount >= 10) result.add('tenPlans');
    if (verifiedEmail) result.add('verifiedEmail');
    return result;
  }
}
