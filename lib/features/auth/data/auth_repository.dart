import 'dart:async';
import 'dart:io';

import '../domain/app_user.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Authentication contract. The UI only talks to this interface, so the
/// backend (Supabase today) can be swapped without touching screens.
abstract interface class AuthRepository {
  /// Whether email / Google / Apple sign-in is available in this build.
  bool get supportsCloudAccounts;

  AppUser? get currentUser;
  Stream<AppUser?> authStateChanges();

  Future<void> signInWithEmail(String email, String password);

  /// Creates an account. The backend sends a verification email.
  Future<void> signUpWithEmail(String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();

  /// Offline profile stored only on this device.
  Future<void> continueOffline();
  Future<void> signOut();
}

/// Remembers across launches that the teacher chose "Continue offline".
class OfflineFlag {
  OfflineFlag(this._file);

  /// In-memory only (tests).
  OfflineFlag.memory() : _file = null;

  final File? _file;
  late bool _value = _file?.existsSync() ?? false;

  bool get value => _value;

  set value(bool v) {
    _value = v;
    final file = _file;
    if (file == null) return;
    if (v) {
      file.writeAsStringSync('1');
    } else if (file.existsSync()) {
      file.deleteSync();
    }
  }
}

/// Used when no backend is configured: only the offline profile exists.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository([OfflineFlag? offline])
    : _offline = offline ?? OfflineFlag.memory() {
    if (_offline.value) _user = AppUser.guest;
  }

  final OfflineFlag _offline;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  bool get supportsCloudAccounts => false;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  Never _unsupported() =>
      throw AuthException('Cloud accounts are not configured in this build.');

  @override
  Future<void> signInWithEmail(String email, String password) async =>
      _unsupported();
  @override
  Future<void> signUpWithEmail(String email, String password) async =>
      _unsupported();
  @override
  Future<void> sendPasswordReset(String email) async => _unsupported();
  @override
  Future<void> signInWithGoogle() async => _unsupported();
  @override
  Future<void> signInWithApple() async => _unsupported();

  @override
  Future<void> continueOffline() async {
    _offline.value = true;
    _controller.add(_user = AppUser.guest);
  }

  @override
  Future<void> signOut() async {
    _offline.value = false;
    _controller.add(_user = null);
  }
}
