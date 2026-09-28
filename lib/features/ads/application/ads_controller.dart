import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../settings/application/preferences_provider.dart';
import '../data/ad_service.dart';
import '../domain/ad_policy.dart';

/// Overridden in `main()`; defaults to no ads (tests, desktop).
final adServiceProvider = Provider<AdService>((ref) => const NoopAdService());

/// Whether the current user should see ads at all right now.
final adsAllowedProvider = Provider<bool>((ref) {
  final prefs = ref.watch(preferencesProvider).asData?.value;
  if (prefs == null) return false;
  return const AdPolicy().adsAllowed(
    platformSupported: ref.watch(adServiceProvider).isSupported,
    enabledInBuild: Env.adsEnabled,
    isPremium: prefs.isPremium,
    adFreeUntil: prefs.adFreeUntil,
    now: DateTime.now(),
  );
});

/// Single entry point screens use to request ads. Applies [AdPolicy].
class AdsController {
  AdsController(this._ref);

  final Ref _ref;
  final _policy = const AdPolicy();
  DateTime? _lastInterstitial;

  bool canShowBanner(AdPlacement placement) =>
      _ref.read(adsAllowedProvider) && _policy.canShowBanner(placement);

  Future<void> maybeShowInterstitial(AdPlacement placement) async {
    final now = DateTime.now();
    if (!_ref.read(adsAllowedProvider)) return;
    if (!_policy.canShowInterstitial(
      placement,
      now: now,
      lastShownAt: _lastInterstitial,
    )) {
      return;
    }
    _lastInterstitial = now;
    await _ref.read(adServiceProvider).showInterstitial();
  }

  /// Rewarded ad → one hour without ads.
  Future<bool> watchRewardedForAdFree() async {
    final earned = await _ref.read(adServiceProvider).showRewarded();
    if (earned) {
      await _ref
          .read(preferencesProvider.notifier)
          .grantAdFree(const Duration(hours: 1));
    }
    return earned;
  }
}

final adsControllerProvider = Provider<AdsController>(AdsController.new);
