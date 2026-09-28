import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/config/env.dart';
import '../domain/app_user.dart';
import 'auth_repository.dart';

/// Supabase-backed accounts: email/password (with verification email),
/// password reset, Google and Apple OAuth. Sessions are persisted and
/// refreshed securely by the Supabase SDK.
///
/// The offline profile is still offered so a teacher can start a class even
/// without internet.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client, [OfflineFlag? offline])
    : _offlineFlag = offline ?? OfflineFlag.memory();

  final sb.SupabaseClient _client;
  final OfflineFlag _offlineFlag;
  final _offline = StreamController<AppUser?>.broadcast();

  bool get _isOffline => _offlineFlag.value;

  @override
  bool get supportsCloudAccounts => true;

  @override
  AppUser? get currentUser =>
      _isOffline ? AppUser.guest : _map(_client.auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield currentUser;
    final cloud = _client.auth.onAuthStateChange.map(
      (s) => _map(s.session?.user),
    );
    yield* StreamGroupLite.merge([
      cloud.where((_) => !_isOffline),
      _offline.stream,
    ]);
  }

  @override
  Future<void> signInWithEmail(String email, String password) => _guard(
    () => _client.auth.signInWithPassword(email: email, password: password),
  );

  @override
  Future<void> signUpWithEmail(String email, String password) => _guard(
    () => _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: Env.authRedirectUrl,
    ),
  );

  @override
  Future<void> sendPasswordReset(String email) => _guard(
    () => _client.auth.resetPasswordForEmail(
      email,
      redirectTo: Env.authRedirectUrl,
    ),
  );

  @override
  Future<void> signInWithGoogle() => _guard(
    () => _client.auth.signInWithOAuth(
      sb.OAuthProvider.google,
      redirectTo: Env.authRedirectUrl,
    ),
  );

  @override
  Future<void> signInWithApple() => _guard(
    () => _client.auth.signInWithOAuth(
      sb.OAuthProvider.apple,
      redirectTo: Env.authRedirectUrl,
    ),
  );

  @override
  Future<void> continueOffline() async {
    _offlineFlag.value = true;
    _offline.add(AppUser.guest);
  }

  @override
  Future<void> signOut() async {
    if (_isOffline) {
      _offlineFlag.value = false;
      _offline.add(_map(_client.auth.currentUser));
      return;
    }
    await _guard(() => _client.auth.signOut());
  }

  Future<void> _guard(Future<Object?> Function() action) async {
    try {
      await action();
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  static AppUser? _map(sb.User? user) =>
      user == null
          ? null
          : AppUser(
            id: user.id,
            email: user.email,
            displayName: user.userMetadata?['full_name'] as String?,
            emailVerified: user.emailConfirmedAt != null,
          );
}

/// Tiny stream merge so we don't pull in a dependency for one call.
abstract final class StreamGroupLite {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    late final StreamController<T> controller;
    final subs = <StreamSubscription<T>>[];
    controller = StreamController<T>(
      onListen: () {
        for (final s in streams) {
          subs.add(s.listen(controller.add, onError: controller.addError));
        }
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return controller.stream;
  }
}
