import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Banner ad slot — renders the shared AdMob banner once loaded, and
/// collapses to nothing while loading or if ads are unavailable.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  @override
  void initState() {
    super.initState();
    AdService().ensureBanner();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: AdService().bannerState,
      builder: (context, loaded, _) {
        final banner = AdService().bannerAd;
        if (!loaded || banner == null) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          color: cs.surfaceVariant.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Center(
            child: AdWidget(ad: banner),
          ),
        );
      },
    );
  }
}
