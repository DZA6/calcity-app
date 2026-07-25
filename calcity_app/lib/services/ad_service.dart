import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  BannerAd? _bannerAd;
  bool _bannerLoaded = false;
  bool _initialized = false;

  bool get bannerLoaded => _bannerLoaded;
  BannerAd? get bannerAd => _bannerAd;

  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  void loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerLoaded = true;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerLoaded = false;
        },
      ),
    );
    _bannerAd!.load();
  }

  void dispose() {
    _bannerAd?.dispose();
  }
}
