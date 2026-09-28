import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../application/ads_controller.dart';
import '../domain/ad_policy.dart';

/// A banner ad that renders nothing when ads are not allowed (premium user,
/// desktop, teaching screen, or the ad failed to load).
class BannerAdSlot extends ConsumerStatefulWidget {
  const BannerAdSlot({super.key, this.placement = AdPlacement.fileBrowser});

  final AdPlacement placement;

  @override
  ConsumerState<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends ConsumerState<BannerAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoad();
  }

  void _maybeLoad() {
    if (_ad != null) return;
    if (!ref.read(adsControllerProvider).canShowBanner(widget.placement)) {
      return;
    }
    _ad = BannerAd(
      adUnitId: ref.read(adServiceProvider).bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => mounted ? setState(() => _loaded = true) : null,
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
    final allowed = ref.watch(adsAllowedProvider);
    if (allowed) _maybeLoad();
    final ad = _ad;
    if (!allowed || ad == null || !_loaded) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
