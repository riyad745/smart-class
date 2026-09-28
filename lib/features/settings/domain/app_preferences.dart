import 'package:flutter/material.dart';

/// Per-account preferences. Synced with the account once cloud sync lands.
class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.system,
    this.isPremium = false,
    this.adFreeUntil,
  });

  final ThemeMode themeMode;

  /// Set by the purchase/entitlement layer. Premium removes all ads.
  final bool isPremium;

  /// Temporary ad-free period earned by watching a rewarded ad.
  final DateTime? adFreeUntil;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    bool? isPremium,
    DateTime? adFreeUntil,
  }) => AppPreferences(
    themeMode: themeMode ?? this.themeMode,
    isPremium: isPremium ?? this.isPremium,
    adFreeUntil: adFreeUntil ?? this.adFreeUntil,
  );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'isPremium': isPremium,
    'adFreeUntil': adFreeUntil?.toIso8601String(),
  };

  factory AppPreferences.fromJson(Map<String, dynamic> json) => AppPreferences(
    themeMode:
        ThemeMode.values.asNameMap()[json['themeMode']] ?? ThemeMode.system,
    isPremium: json['isPremium'] as bool? ?? false,
    adFreeUntil:
        json['adFreeUntil'] == null
            ? null
            : DateTime.tryParse(json['adFreeUntil'] as String),
  );
}
