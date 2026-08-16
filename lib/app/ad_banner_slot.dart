import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/monetization_controller.dart';

class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({super.key});

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot> {
  static const _testIosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  static const _releaseBannerId = 'ca-app-pub-8572237347685622/8817738951';

  BannerAd? _banner;
  bool _loaded = false;

  String? get _adUnitId {
    if (kDebugMode) return _testIosBannerId;
    return _releaseBannerId.isEmpty ? null : _releaseBannerId;
  }

  @override
  void initState() {
    super.initState();
    MonetizationController.instance.addListener(_syncAd);
    _syncAd();
  }

  void _syncAd() {
    final monetization = MonetizationController.instance;
    final shouldLoad = monetization.canShowAds && !monetization.premium;
    if (shouldLoad && _banner == null && _adUnitId != null) {
      final banner = BannerAd(
        adUnitId: _adUnitId!,
        size: AdSize.banner,
        request: const AdRequest(nonPersonalizedAds: true),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, _) {
            ad.dispose();
            if (mounted) setState(() => _banner = null);
          },
        ),
      );
      _banner = banner;
      banner.load();
    } else if (!shouldLoad && _banner != null) {
      _banner?.dispose();
      _banner = null;
      _loaded = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    MonetizationController.instance.removeListener(_syncAd);
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (!_loaded || banner == null || MonetizationController.instance.premium) {
      return const SizedBox.shrink();
    }
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: banner.size.height.toDouble(),
          child: Center(
            child: SizedBox(
              width: banner.size.width.toDouble(),
              height: banner.size.height.toDouble(),
              child: AdWidget(ad: banner),
            ),
          ),
        ),
      ),
    );
  }
}
