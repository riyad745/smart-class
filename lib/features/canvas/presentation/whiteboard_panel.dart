import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/canvas_document_controller.dart';
import '../application/canvas_providers.dart';
import '../domain/board_background.dart';
import 'whiteboard_view.dart';
import 'widgets/canvas_toolbar.dart';

/// A complete multi-page whiteboard: canvas, floating toolbar, background
/// picker and page navigation. Used full-screen and inside split screen.
class WhiteboardPanel extends ConsumerStatefulWidget {
  const WhiteboardPanel({
    super.key,
    required this.controller,
    this.showToolbar = true,
    this.toolbarLeading = const [],
    this.toolbarTrailing = const [],
  });

  final CanvasDocumentController controller;
  final bool showToolbar;
  final List<Widget> toolbarLeading;
  final List<Widget> toolbarTrailing;

  @override
  ConsumerState<WhiteboardPanel> createState() => _WhiteboardPanelState();
}

class _WhiteboardPanelState extends ConsumerState<WhiteboardPanel> {
  final _view = WhiteboardViewController();
  int _page = 0;
  late int _pageCount = widget.controller.document.pageCount;

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    setState(() {
      _page = page;
      if (_page >= _pageCount) _pageCount = _page + 1;
    });
    _view.reset();
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear this page?'),
            content: const Text('You can undo this.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
    if (ok ?? false) widget.controller.clearPage(_page);
  }

  void _setBackground(BoardBackground background) {
    widget.controller.setBackground(_page, background);
    ref.read(toolSettingsProvider.notifier).adaptToBackground(background);
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.controller.page(_page).background;
    return Stack(
      children: [
        Positioned.fill(
          child: WhiteboardView(
            key: ValueKey(_page),
            controller: widget.controller,
            pageIndex: _page,
            viewController: _view,
          ),
        ),
        if (widget.showToolbar)
          Positioned(
            left: 8,
            right: 8,
            top: 8,
            child: Align(
              alignment: Alignment.topCenter,
              child: CanvasToolbar(
                controller: widget.controller,
                onClear: _confirmClear,
                leading: widget.toolbarLeading,
                trailing: [
                  PopupMenuButton<BoardBackground>(
                    tooltip: 'Background',
                    icon: const Icon(Icons.wallpaper),
                    initialValue: background,
                    onSelected: _setBackground,
                    itemBuilder:
                        (_) => [
                          for (final b in BoardBackground.values)
                            PopupMenuItem(
                              value: b,
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Color(b.color),
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(b.label),
                                ],
                              ),
                            ),
                        ],
                  ),
                  ...widget.toolbarTrailing,
                ],
              ),
            ),
          ),
        if (widget.showToolbar)
          Positioned(
            right: 12,
            bottom: 12,
            child: _PageNavigator(
              page: _page,
              pageCount: _pageCount,
              zoomListenable: _view,
              zoom: () => _view.zoom,
              onPrevious: _page > 0 ? () => _goTo(_page - 1) : null,
              onNext: () => _goTo(_page + 1),
              onResetZoom: _view.reset,
            ),
          ),
      ],
    );
  }
}

class _PageNavigator extends StatelessWidget {
  const _PageNavigator({
    required this.page,
    required this.pageCount,
    required this.zoomListenable,
    required this.zoom,
    required this.onPrevious,
    required this.onNext,
    required this.onResetZoom,
  });

  final int page;
  final int pageCount;
  final Listenable zoomListenable;
  final double Function() zoom;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final VoidCallback onResetZoom;

  @override
  Widget build(BuildContext context) {
    final isLast = page == pageCount - 1;
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListenableBuilder(
            listenable: zoomListenable,
            builder:
                (context, _) => TextButton(
                  onPressed: onResetZoom,
                  child: Text('${(zoom() * 100).round()}%'),
                ),
          ),
          IconButton(
            tooltip: 'Previous page',
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Text('${page + 1} / $pageCount'),
          IconButton(
            tooltip: isLast ? 'Add page' : 'Next page',
            icon: Icon(isLast ? Icons.add : Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
