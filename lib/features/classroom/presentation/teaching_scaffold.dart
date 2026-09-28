import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ads/application/ads_controller.dart';
import '../../ads/domain/ad_policy.dart';
import '../application/classroom_tools_provider.dart';
import 'classroom_overlay.dart';

/// Scaffold for every teaching screen (whiteboard, PDF, split screen).
///
/// * Hides the app bar in zen mode so the shared screen stays clean.
/// * Hosts the classroom tools overlay (spotlight, timer).
/// * Never shows ads while teaching; an interstitial may be shown only after
///   the session is closed (see [AdPolicy]).
class TeachingScaffold extends ConsumerWidget {
  const TeachingScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zen = ref.watch(classroomToolsProvider.select((s) => s.zenMode));
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        ref.read(classroomToolsProvider.notifier).reset();
        ref
            .read(adsControllerProvider)
            .maybeShowInterstitial(AdPlacement.sessionExit);
      },
      child: Scaffold(
        appBar:
            zen
                ? null
                : AppBar(
                  title: Text(title, overflow: TextOverflow.ellipsis),
                  actions: [...actions, const ClassroomToolsMenu()],
                ),
        body: SafeArea(
          top: zen,
          bottom: false,
          child: ClassroomOverlay(child: body),
        ),
      ),
    );
  }
}

class ClassroomToolsMenu extends ConsumerWidget {
  const ClassroomToolsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tools = ref.watch(classroomToolsProvider);
    final notifier = ref.read(classroomToolsProvider.notifier);
    return MenuAnchor(
      builder:
          (context, controller, _) => IconButton(
            tooltip: 'Classroom tools',
            icon: const Icon(Icons.co_present_outlined),
            onPressed:
                () =>
                    controller.isOpen ? controller.close() : controller.open(),
          ),
      menuChildren: [
        CheckboxMenuButton(
          value: tools.spotlight,
          onChanged: (_) => notifier.toggleSpotlight(),
          child: const Text('Spotlight'),
        ),
        CheckboxMenuButton(
          value: tools.timerVisible,
          onChanged: (_) => notifier.toggleTimer(),
          child: const Text('Timer / stopwatch'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.fullscreen),
          onPressed: notifier.toggleZen,
          child: const Text('Zen mode (hide UI)'),
        ),
      ],
    );
  }
}
