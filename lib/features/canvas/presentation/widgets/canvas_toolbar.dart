import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/canvas_document_controller.dart';
import '../../application/canvas_providers.dart';
import '../../domain/drawing_tool.dart';
import '../../domain/tool_settings.dart';

/// Floating drawing toolbar shared by the whiteboard and the PDF annotator.
///
/// Scrolls horizontally on narrow screens. Extra, screen-specific actions go
/// in [leading] / [trailing].
class CanvasToolbar extends ConsumerWidget {
  const CanvasToolbar({
    super.key,
    required this.controller,
    required this.onClear,
    this.leading = const [],
    this.trailing = const [],
  });

  final CanvasDocumentController controller;
  final VoidCallback onClear;
  final List<Widget> leading;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(toolSettingsProvider);
    final notifier = ref.read(toolSettingsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    Widget toolButton(DrawingTool tool, IconData icon, String tooltip) =>
        _ToolButton(
          icon: icon,
          tooltip: tooltip,
          selected: settings.tool == tool,
          onPressed: () => notifier.selectTool(tool),
        );

    return Material(
      elevation: 4,
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...leading,
            toolButton(DrawingTool.pen, Icons.edit, 'Pen'),
            toolButton(DrawingTool.pencil, Icons.create_outlined, 'Pencil'),
            toolButton(DrawingTool.marker, Icons.brush, 'Marker'),
            toolButton(DrawingTool.highlighter, Icons.highlight, 'Highlighter'),
            toolButton(
              DrawingTool.eraser,
              Icons.cleaning_services_outlined,
              'Eraser',
            ),
            _ShapeMenu(
              selected: settings.tool,
              onSelected: notifier.selectTool,
            ),
            toolButton(DrawingTool.laser, Icons.flare, 'Laser pointer'),
            const _Divider(),
            for (final color in ToolSettings.palette)
              _ColorDot(
                color: Color(color),
                selected: settings.color == color && settings.tool.isPersistent,
                onTap: () => notifier.setColor(color),
              ),
            _WidthMenu(width: settings.width, onSelected: notifier.setWidth),
            const _Divider(),
            ListenableBuilder(
              listenable: controller,
              builder:
                  (context, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Undo',
                        icon: const Icon(Icons.undo),
                        onPressed: controller.canUndo ? controller.undo : null,
                      ),
                      IconButton(
                        tooltip: 'Redo',
                        icon: const Icon(Icons.redo),
                        onPressed: controller.canRedo ? controller.redo : null,
                      ),
                    ],
                  ),
            ),
            IconButton(
              tooltip: 'Clear page',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: onClear,
            ),
            IconButton(
              tooltip:
                  settings.inputMode == InputMode.stylusOnly
                      ? 'Stylus only (palm rejection on) — fingers pan & zoom'
                      : 'Finger drawing on',
              isSelected: settings.inputMode == InputMode.stylusOnly,
              icon: const Icon(Icons.touch_app_outlined),
              selectedIcon: const Icon(Icons.do_not_touch_outlined),
              onPressed:
                  () => notifier.setInputMode(
                    settings.inputMode == InputMode.stylusOnly
                        ? InputMode.any
                        : InputMode.stylusOnly,
                  ),
            ),
            ...trailing,
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    isSelected: selected,
    style: IconButton.styleFrom(
      backgroundColor:
          selected ? Theme.of(context).colorScheme.primaryContainer : null,
    ),
    icon: Icon(icon),
    onPressed: onPressed,
  );
}

class _ShapeMenu extends StatelessWidget {
  const _ShapeMenu({required this.selected, required this.onSelected});

  final DrawingTool selected;
  final ValueChanged<DrawingTool> onSelected;

  static const _shapes = {
    DrawingTool.line: (Icons.horizontal_rule, 'Straight line'),
    DrawingTool.arrow: (Icons.arrow_right_alt, 'Arrow'),
    DrawingTool.rectangle: (Icons.crop_square, 'Rectangle'),
    DrawingTool.ellipse: (Icons.circle_outlined, 'Circle / ellipse'),
  };

  @override
  Widget build(BuildContext context) {
    final current = _shapes[selected];
    return PopupMenuButton<DrawingTool>(
      tooltip: 'Shapes',
      onSelected: onSelected,
      itemBuilder:
          (_) => [
            for (final e in _shapes.entries)
              PopupMenuItem(
                value: e.key,
                child: ListTile(
                  leading: Icon(e.value.$1),
                  title: Text(e.value.$2),
                ),
              ),
          ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              current != null
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(current?.$1 ?? Icons.category_outlined),
      ),
    );
  }
}

class _WidthMenu extends StatelessWidget {
  const _WidthMenu({required this.width, required this.onSelected});

  final double width;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<double>(
    tooltip: 'Stroke size',
    onSelected: onSelected,
    itemBuilder:
        (_) => [
          for (final w in ToolSettings.widths)
            PopupMenuItem(
              value: w,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: w,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Text(w.toStringAsFixed(w == w.roundToDouble() ? 0 : 1)),
                ],
              ),
            ),
        ],
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(Icons.line_weight, semanticLabel: 'Stroke size $width'),
    ),
  );
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: selected ? 26 : 20,
          height: selected ? 26 : 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.primary : outline,
              width: selected ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 28, child: VerticalDivider(width: 12));
}
