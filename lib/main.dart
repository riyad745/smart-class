import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import 'app/app.dart';
import 'core/config/env.dart';
import 'features/ads/application/ads_controller.dart';
import 'features/ads/data/ad_service.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/supabase_auth_repository.dart';

/// Composition root: the only place concrete services are chosen.
/// Everything else depends on interfaces through Riverpod providers.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final docs = await getApplicationSupportDirectory();
  final appDir = Directory(p.join(docs.path, 'smart_class'));
  await appDir.create(recursive: true);

  final offline = OfflineFlag(File(p.join(appDir.path, 'offline_mode')));
  AuthRepository auth = LocalAuthRepository(offline);
  if (Env.hasBackend) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
    auth = SupabaseAuthRepository(Supabase.instance.client, offline);
  }

  final AdService ads =
      AdMobAdService.platformSupported
          ? AdMobAdService()
          : const NoopAdService();
  // Don't block the first frame on the ad SDK.
  ads.initialize();

  runApp(
    ProviderScope(
      overrides: [
        appDirectoryProvider.overrideWithValue(appDir),
        authRepositoryProvider.overrideWithValue(auth),
        adServiceProvider.overrideWithValue(ads),
      ],
      child: const SmartClassApp(),
    ),
  );
}
