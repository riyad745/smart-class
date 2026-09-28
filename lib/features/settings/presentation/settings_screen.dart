import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/dialogs.dart';
import '../../ads/application/ads_controller.dart';
import '../../auth/application/auth_providers.dart';
import '../../canvas/application/canvas_providers.dart';
import '../../canvas/domain/tool_settings.dart';
import '../application/preferences_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider).asData?.value;
    final user = ref.watch(currentUserProvider);
    final tools = ref.watch(toolSettingsProvider);
    final adsSupported = ref.watch(adServiceProvider).isSupported;
    final adsAllowed = ref.watch(adsAllowedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body:
          prefs == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(user?.label ?? ''),
                    subtitle: Text(
                      user == null
                          ? ''
                          : user.isGuest
                          ? 'Offline profile · stored on this device only'
                          : '${user.email ?? ''}${user.emailVerified ? '' : ' · email not verified'}',
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Theme'),
                    trailing: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Auto'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {prefs.themeMode},
                      onSelectionChanged:
                          (s) => ref
                              .read(preferencesProvider.notifier)
                              .setThemeMode(s.first),
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.do_not_touch_outlined),
                    title: const Text('Stylus only (palm rejection)'),
                    subtitle: const Text(
                      'Only a pen or mouse draws; fingers scroll and zoom. '
                      'Recommended for iPad + Apple Pencil and S Pen tablets.',
                    ),
                    value: tools.inputMode == InputMode.stylusOnly,
                    onChanged:
                        (v) => ref
                            .read(toolSettingsProvider.notifier)
                            .setInputMode(
                              v ? InputMode.stylusOnly : InputMode.any,
                            ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.workspace_premium_outlined),
                    title: const Text('Premium (no ads)'),
                    subtitle: const Text(
                      'Developer toggle until in-app purchases are added.',
                    ),
                    value: prefs.isPremium,
                    onChanged:
                        (v) => ref
                            .read(preferencesProvider.notifier)
                            .setPremium(v),
                  ),
                  if (adsSupported && adsAllowed)
                    ListTile(
                      leading: const Icon(Icons.ondemand_video_outlined),
                      title: const Text('Watch an ad for 1 hour ad-free'),
                      onTap: () async {
                        final ok =
                            await ref
                                .read(adsControllerProvider)
                                .watchRewardedForAdFree();
                        if (context.mounted) {
                          showMessage(
                            context,
                            ok
                                ? 'Enjoy 1 hour without ads!'
                                : 'No ad available right now.',
                          );
                        }
                      },
                    ),
                  if (!adsSupported)
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Ads are not shown on this platform.'),
                    ),
                ],
              ),
    );
  }
}
