/// Where in the app an ad could appear.
enum AdPlacement {
  /// Home / file manager: banner allowed.
  fileBrowser,

  /// Leaving a teaching session back to the file manager: interstitial
  /// allowed, frequency-capped.
  sessionExit,

  /// Whiteboard, PDF reader, split screen, presentation: never any ads.
  teaching,
}

/// Pure decision logic for when ads may be shown. Keeping this separate from
/// the ad SDK makes the rules explicit and unit-testable.
class AdPolicy {
  const AdPolicy({this.interstitialCooldown = const Duration(minutes: 5)});

  final Duration interstitialCooldown;

  bool adsAllowed({
    required bool platformSupported,
    required bool enabledInBuild,
    required bool isPremium,
    required DateTime? adFreeUntil,
    required DateTime now,
  }) =>
      platformSupported &&
      enabledInBuild &&
      !isPremium &&
      (adFreeUntil == null || now.isAfter(adFreeUntil));

  bool canShowBanner(AdPlacement placement) =>
      placement == AdPlacement.fileBrowser;

  bool canShowInterstitial(
    AdPlacement placement, {
    required DateTime now,
    required DateTime? lastShownAt,
  }) =>
      placement == AdPlacement.sessionExit &&
      (lastShownAt == null ||
          now.difference(lastShownAt) >= interstitialCooldown);
}
