import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob IDs. REAL Android pair live — iOS still test.
class Ads {
  static String get bannerId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1088997129209291/1009324670'; // Android real banner
    }
    return 'ca-app-pub-3940256099942544/2934735716'; // iOS test banner
  }
}

/// Top banner shown where the old AppBar title used to live.
/// Collapses to nothing if the ad fails to load (offline etc).
class FoxAdBanner extends StatefulWidget {
  const FoxAdBanner({super.key});
  @override
  State<FoxAdBanner> createState() => _FoxAdBannerState();
}

class _FoxAdBannerState extends State<FoxAdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: Ads.bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      // White bed so a 468-wide creative never shows black bars
      // inside our 320x50 hole.
      color: Colors.white,
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      margin: const EdgeInsets.only(top: 6),
      child: AdWidget(ad: ad),
    );
  }
}
