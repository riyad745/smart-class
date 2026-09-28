import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/features/ads/domain/ad_policy.dart';

void main() {
  const policy = AdPolicy(interstitialCooldown: Duration(minutes: 5));
  final now = DateTime(2026, 1, 1, 12);

  bool allowed({
    bool supported = true,
    bool premium = false,
    DateTime? adFreeUntil,
  }) => policy.adsAllowed(
    platformSupported: supported,
    enabledInBuild: true,
    isPremium: premium,
    adFreeUntil: adFreeUntil,
    now: now,
  );

  test('free users on mobile see ads', () => expect(allowed(), isTrue));
  test('premium removes ads', () => expect(allowed(premium: true), isFalse));
  test('desktop has no ads', () => expect(allowed(supported: false), isFalse));
  test('rewarded ad-free period is respected', () {
    expect(allowed(adFreeUntil: now.add(const Duration(minutes: 1))), isFalse);
    expect(
      allowed(adFreeUntil: now.subtract(const Duration(minutes: 1))),
      isTrue,
    );
  });

  test('never any ads while teaching', () {
    expect(policy.canShowBanner(AdPlacement.teaching), isFalse);
    expect(
      policy.canShowInterstitial(
        AdPlacement.teaching,
        now: now,
        lastShownAt: null,
      ),
      isFalse,
    );
  });

  test('banner only in the file browser', () {
    expect(policy.canShowBanner(AdPlacement.fileBrowser), isTrue);
  });

  test('interstitials are frequency capped', () {
    expect(
      policy.canShowInterstitial(
        AdPlacement.sessionExit,
        now: now,
        lastShownAt: null,
      ),
      isTrue,
    );
    expect(
      policy.canShowInterstitial(
        AdPlacement.sessionExit,
        now: now,
        lastShownAt: now.subtract(const Duration(minutes: 2)),
      ),
      isFalse,
    );
    expect(
      policy.canShowInterstitial(
        AdPlacement.sessionExit,
        now: now,
        lastShownAt: now.subtract(const Duration(minutes: 6)),
      ),
      isTrue,
    );
  });
}
