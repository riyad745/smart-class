import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/canvas/presentation/whiteboard_screen.dart';
import '../features/files/presentation/files_screen.dart';
import '../features/pdf/presentation/pdf_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'routes.dart';

/// App navigation. Signed-out users are always redirected to sign-in.
final routerProvider = Provider<GoRouter>((ref) {
  final signedIn = ValueNotifier<bool?>(null);
  ref.listen(
    authStateProvider,
    (_, next) =>
        signedIn.value = next.isLoading ? null : next.asData?.value != null,
    fireImmediately: true,
  );
  ref.onDispose(signedIn.dispose);

  return GoRouter(
    refreshListenable: signedIn,
    redirect: (context, state) {
      final auth = signedIn.value;
      if (auth == null) return null; // still restoring the session
      final atSignIn = state.matchedLocation == AppRoutes.signIn;
      if (!auth) return atSignIn ? null : AppRoutes.signIn;
      if (atSignIn) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, _) => const FilesScreen()),
      GoRoute(path: AppRoutes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.boardPattern,
        builder:
            (_, state) => WhiteboardScreen(fileId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.pdfPattern,
        builder: (_, state) => PdfScreen(fileId: state.pathParameters['id']!),
      ),
    ],
  );
});
