import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Presentation aids shown on top of any teaching screen.
class ClassroomToolsState {
  const ClassroomToolsState({
    this.zenMode = false,
    this.spotlight = false,
    this.timerVisible = false,
    this.toolbarVisible = true,
  });

  /// Hides all app chrome so the shared screen shows only the content.
  final bool zenMode;

  /// Dims everything except a circle around the pointer.
  final bool spotlight;
  final bool timerVisible;

  /// Drawing toolbars can be hidden to maximise the teaching area.
  final bool toolbarVisible;

  ClassroomToolsState copyWith({
    bool? zenMode,
    bool? spotlight,
    bool? timerVisible,
    bool? toolbarVisible,
  }) => ClassroomToolsState(
    zenMode: zenMode ?? this.zenMode,
    spotlight: spotlight ?? this.spotlight,
    timerVisible: timerVisible ?? this.timerVisible,
    toolbarVisible: toolbarVisible ?? this.toolbarVisible,
  );
}

class ClassroomToolsController extends Notifier<ClassroomToolsState> {
  @override
  ClassroomToolsState build() => const ClassroomToolsState();

  void toggleZen() {
    final zen = !state.zenMode;
    state = state.copyWith(zenMode: zen);
    // Immersive full screen on phones/tablets; no-op on desktop.
    SystemChrome.setEnabledSystemUIMode(
      zen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void toggleSpotlight() => state = state.copyWith(spotlight: !state.spotlight);
  void toggleTimer() =>
      state = state.copyWith(timerVisible: !state.timerVisible);
  void toggleToolbar() =>
      state = state.copyWith(toolbarVisible: !state.toolbarVisible);

  void reset() {
    if (state.zenMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    state = const ClassroomToolsState();
  }
}

final classroomToolsProvider =
    NotifierProvider<ClassroomToolsController, ClassroomToolsState>(
      ClassroomToolsController.new,
    );
