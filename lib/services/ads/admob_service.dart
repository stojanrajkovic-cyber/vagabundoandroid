import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_config.dart';

/// Faza 8 — AdMob interstitial/init. Banneri se učitavaju direktno u
/// AdBannerWidget (widgets/ads/), ne prolaze kroz ovaj servis.
class AdMobService {
  AdMobService._();
  static final AdMobService instance = AdMobService._();

  static const _generationCountKey = 'ad_generation_count';
  static const _showEveryNth = 3;

  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitial();
  }

  void _loadInterstitial() {
    if (_isLoadingInterstitial) return;
    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          // ignore: avoid_print
          print('❌ AdMobService interstitial load error: $error');
          _isLoadingInterstitial = false;
        },
      ),
    );
  }

  /// Pozovi ODMAH kad korisnik tapne Generate — NE čeka da se ad zatvori
  /// prije nego što stvarno generisanje krene (pozivalac to radi paralelno).
  /// Prikazuje se SAMO na svaki treći poziv (frequency cap), i SAMO ako je
  /// ad već učitan (ne blokira/čeka učitavanje).
  Future<void> maybeShowInterstitial() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_generationCountKey) ?? 0) + 1;
    await prefs.setInt(_generationCountKey, count);

    if (count % _showEveryNth != 0) return;

    final ad = _interstitialAd;
    if (ad == null) return; // nije stigao da se učita — tiho preskoči, ne blokiraj generisanje

    _interstitialAd = null; // spriječi dupli show() istog ad objekta
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial(); // učitaj sljedeći odmah
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    await ad.show();
  }
}
