import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/canvas_repository.dart';
import '../domain/board_background.dart';
import '../domain/drawing_tool.dart';
import '../domain/tool_settings.dart';

final canvasRepositoryProvider = Provider<CanvasRepository>(
  (ref) => CanvasRepository(ref.watch(userStorageProvider).store),
);

/// Selected pen/tool, shared by the whiteboard and PDF annotation.
class ToolSettingsController extends Notifier<ToolSettings> {
  @override
  ToolSettings build() => const ToolSettings();

  void selectTool(DrawingTool tool) => state = state.copyWith(tool: tool);

  void setColor(int color) {
    // Picking a colour while erasing/lasering implies the teacher wants to write.
    final tool = state.tool.isPersistent ? state.tool : DrawingTool.pen;
    state = state.copyWith(color: color, tool: tool);
  }

  void setWidth(double width) => state = state.copyWith(width: width);
  void setInputMode(InputMode mode) => state = state.copyWith(inputMode: mode);

  /// Switch ink to a colour readable on [background] (e.g. white on blackboard).
  void adaptToBackground(BoardBackground background) {
    final dark = background.isDark;
    final inkIsDark = state.color == 0xFF1F2937;
    final inkIsLight = state.color == 0xFFFFFFFF;
    if ((dark && inkIsDark) || (!dark && inkIsLight)) {
      state = state.copyWith(color: background.defaultInkColor);
    }
  }
}

final toolSettingsProvider =
    NotifierProvider<ToolSettingsController, ToolSettings>(
      ToolSettingsController.new,
    );
