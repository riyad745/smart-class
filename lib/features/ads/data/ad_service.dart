import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/env.dart';

/// Wraps the ad SDK. Screens never import `google_mobile_ads` directly;
/// they use [AdService] and `BannerAdSlot`, so the network can be swapped.
abstract interface class AdService {
  /// AdMob only supports Android and iOS. Desktop builds are ad-free.
  bool get isSupported;
  Future<void> initialize();
  String get bannerUnitId;

  /// Shows a preloaded interstitial if one is ready. Never blocks.
  Future<void> showInterstitial();

  /// Shows a rewarded ad; completes with true if the reward was earned.
  Future<bool> showRewarded();
}

class NoopAdService implements AdService {
  const NoopAdService();
  @override
  bool get isSupported => false;
  @override
  Future<void> initialize() async {}
  @override
  String get bannerUnitId => '';
  @override
  Future<void> showInterstitial() async {}
  @override
  Future<bool> showRewarded() async => false;
}

class AdMobAdService implements AdService {
  InterstitialAd? _interstitial;
  bool _initialized = false;

  static bool get platformSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  bool get isSupported => platformSupported;

  @override
  String get bannerUnitId =>
      Platform.isAndroid ? Env.admobBannerAndroid : Env.admobBannerIos;

  String get _interstitialUnitId =>
      Platform.isAndroid
          ? Env.admobInterstitialAndroid
          : Env.admobInterstitialIos;

  String get _rewardedUnitId =>
      Platform.isAndroid ? Env.admobRewardedAndroid : Env.admobRewardedIos;

  @override
  Future<void> initialize() async {
    if (_initialized || !isSupported) return;
    _initialized = true;
    await MobileAds.instance.initialize();
    _preloadInterstitial();
  }

  void _preloadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) => _interstitial = null,
      ),
    );
  }

  @override
  Future<void> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) return;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _preloadInterstitial();
      },
    );
    await ad.show();
  }

  @override
  Future<bool> showRewarded() async {
    final loaded = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: loaded.complete,
        onAdFailedToLoad: (_) => loaded.complete(null),
      ),
    );
    final ad = await loaded.future;
    if (ad == null) return false;

    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!done.isCompleted) done.complete(false);
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return done.future;
  }
}
