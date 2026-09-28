/// The signed-in user. All user data is namespaced by [id], so accounts on a
/// shared device never see each other's files.
class AppUser {
  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.isGuest = false,
    this.emailVerified = false,
  });

  /// Local, offline-only profile used when no backend is configured or the
  /// teacher chooses "Continue offline".
  static const guest = AppUser(
    id: 'local-guest',
    displayName: 'Offline',
    isGuest: true,
  );

  final String id;
  final String? email;
  final String? displayName;
  final bool isGuest;
  final bool emailVerified;

  String get label => displayName ?? email ?? 'Teacher';
}
