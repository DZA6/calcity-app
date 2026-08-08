import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform, ValueNotifier, debugPrint;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob wrapper for the CalCity app.
///
/// Ad unit IDs come from --dart-define at build time and default to Google's
/// OFFICIAL TEST IDs, so every dev/debug build is safe:
///
///   flutter build apk --release \
///     --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXXX/YYYY \
///     --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-XXXX/ZZZZ
///
/// The AdMob App ID lives in AndroidManifest.xml (meta-data
/// com.google.android.gms.ads.APPLICATION_ID) — swap the test App ID there
/// before shipping a release that serves real ads.
class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  // Test ad units (Google's official sample IDs — safe for dev builds)
  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  static const String _envBanner = String.fromEnvironment('ADMOB_BANNER_ID');
  static const String _envInterstitial =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ID');

  String get bannerUnitId => _envBanner.isNotEmpty ? _envBanner : _testBanner;
  String get interstitialUnitId =>
      _envInterstitial.isNotEmpty ? _envInterstitial : _testInterstitial;

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _initialized = false;
  bool _bannerRequested = false;
  DateTime _lastInterstitialShown = DateTime.fromMillisecondsSinceEpoch(0);

  BannerAd? get bannerAd => _bannerAd;

  /// Notifies listeners when the banner becomes available/unavailable.
  final ValueNotifier<bool> bannerState = ValueNotifier(false);

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (_initialized) return;
    if (!_isSupportedPlatform) {
      _initialized = true;
      return;
    }
    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      // Ads not available on this device — app keeps working
    }
    _initialized = true;
  }

  // ── Banner ────────────────────────────────────────────────────────

  /// Load the banner once (idempotent). Widgets rebuild via [bannerState].
  void ensureBanner() {
    if (!_isSupportedPlatform || _bannerRequested) return;
    _bannerRequested = true;

    _bannerAd = BannerAd(
      adUnitId: bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => bannerState.value = true,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          _bannerRequested = false; // allow a retry on next visibility
          bannerState.value = false;
          debugPrint('AdMob banner failed: ${error.code} ${error.message}');
        },
        onAdImpression: (_) {},
      ),
    )..load();
  }

  // ── Interstitial ──────────────────────────────────────────────────

  /// Preload an interstitial so it is ready when the user navigates.
  void preloadInterstitial() {
    if (!_isSupportedPlatform || _interstitialAd != null) return;
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) => _interstitialAd = null,
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitialAd = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob interstitial failed: ${error.code}');
        },
      ),
    );
  }

  /// Show the interstitial if one is loaded AND the cooldown has passed.
  /// Returns true if an ad was shown.
  bool showInterstitialIfReady({Duration cooldown = const Duration(minutes: 2)}) {
    final ad = _interstitialAd;
    if (ad == null) {
      preloadInterstitial();
      return false;
    }
    final since = DateTime.now().difference(_lastInterstitialShown);
    if (since < cooldown) return false;
    ad.show();
    _lastInterstitialShown = DateTime.now();
    _interstitialAd = null;
    preloadInterstitial(); // keep one warm
    return true;
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    bannerState.value = false;
  }
}
