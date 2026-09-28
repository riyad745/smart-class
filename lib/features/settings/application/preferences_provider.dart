import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/app_preferences.dart';

const _key = 'preferences';

/// Per-account preferences, loaded once and saved on every change.
class PreferencesController extends AsyncNotifier<AppPreferences> {
  @override
  Future<AppPreferences> build() async {
    final json = await ref.watch(userStorageProvider).store.read(_key);
    return json == null
        ? const AppPreferences()
        : AppPreferences.fromJson(json);
  }

  Future<void> _update(AppPreferences Function(AppPreferences) change) async {
    final next = change(state.asData?.value ?? const AppPreferences());
    state = AsyncData(next);
    await ref.read(userStorageProvider).store.write(_key, next.toJson());
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _update((p) => p.copyWith(themeMode: mode));

  /// Placeholder until in-app purchases are wired up (Phase 3). The rest of
  /// the app only reads `isPremium`, so plugging in a real entitlement
  /// source is a change in one place.
  Future<void> setPremium(bool value) =>
      _update((p) => p.copyWith(isPremium: value));

  Future<void> grantAdFree(Duration duration) =>
      _update((p) => p.copyWith(adFreeUntil: DateTime.now().add(duration)));
}

final preferencesProvider =
    AsyncNotifierProvider<PreferencesController, AppPreferences>(
      PreferencesController.new,
    );

/// Theme mode is needed above the signed-in area, so default when signed out.
final themeModeProvider = Provider<ThemeMode>((ref) {
  if (ref.watch(currentUserProvider) == null) return ThemeMode.system;
  return ref.watch(preferencesProvider).asData?.value.themeMode ??
      ThemeMode.system;
});
