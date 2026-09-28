import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/user_storage.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

/// Root directory for app data. Overridden in `main()` once
/// `path_provider` has resolved it, so every other provider stays synchronous.
final appDirectoryProvider = Provider<Directory>(
  (ref) => throw UnimplementedError('appDirectoryProvider must be overridden'),
);

/// Overridden in `main()` with the Supabase or local implementation.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => LocalAuthRepository(),
);

final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authStateProvider).asData?.value,
);

/// Storage for the signed-in account. Everything user-specific (files,
/// canvases, preferences) is built on top of this, so signing out or
/// switching account automatically rebuilds all data providers.
final userStorageProvider = Provider<UserStorage>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw StateError('No user signed in');
  return UserStorage.forUser(ref.watch(appDirectoryProvider), user.id);
});
