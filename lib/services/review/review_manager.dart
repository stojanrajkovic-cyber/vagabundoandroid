import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Port ReviewManager.swift — milestone/cooldown logika (2/5/10 završenih
/// putovanja, 10 dana cooldown). Android hibridni pristup: milestone prompt
/// otvara custom dijalog pa tihi In-App Review poziv, dok eksplicitno
/// dugme (top bar star) ide direktno na Play Store.
class ReviewManager {
  ReviewManager._();
  static final ReviewManager instance = ReviewManager._();

  static const _milestones = {2, 5, 10};
  static const _cooldownDays = 10;

  static const _completedKey = 'completed_plans_count';
  static const _lastPromptKey = 'last_review_prompt_date';

  /// Pozovi kad se putovanje označi kao završeno. Vraća true ako UI treba
  /// prikazati custom "Rate Vagabundo" prompt.
  Future<bool> registerCompletedTrip() async {
    final prefs = await SharedPreferences.getInstance();

    final newCount = (prefs.getInt(_completedKey) ?? 0) + 1;
    await prefs.setInt(_completedKey, newCount);

    if (!_milestones.contains(newCount)) return false;

    final lastMillis = prefs.getInt(_lastPromptKey);
    if (lastMillis != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMillis);
      final days = DateTime.now().difference(last).inDays;
      if (days < _cooldownDays) return false;
    }

    await prefs.setInt(_lastPromptKey, DateTime.now().millisecondsSinceEpoch);
    return true;
  }

  /// Google Play In-App Review API — tih poziv, Google odlučuje da li se
  /// stvarno prikaže. NEMA povratne informacije o tome, to je normalno.
  Future<void> requestReview() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
  }

  /// Direktan Play Store link — koristi za EKSPLICITNO dugme (top bar star
  /// ikonica), garantovano otvara store stranicu.
  Future<void> openPlayStorePage() async {
    const packageName = 'com.stojanrajkovic.vagabundo';
    final uri = Uri.parse('market://details?id=$packageName');
    final webUri =
        Uri.parse('https://play.google.com/store/apps/details?id=$packageName');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}
