import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/canvas_document_controller.dart';
import '../application/canvas_providers.dart';
import 'drawing_surface.dart';
import 'painters/background_painter.dart';

/// An infinite, pannable and zoomable whiteboard page.
///
/// * Fingers (two, or one in stylus-only mode) pan and pinch-zoom.
/// * Mouse wheel pans; Ctrl/⌘ + wheel or trackpad pinch zooms.
class WhiteboardView extends ConsumerStatefulWidget {
  const WhiteboardView({
    super.key,
    required this.controller,
    required this.pageIndex,
    this.viewController,
  });

  final CanvasDocumentController controller;
  final int pageIndex;
  final WhiteboardViewController? viewController;

  @override
  ConsumerState<WhiteboardView> createState() => _WhiteboardViewState();
}

/// Lets toolbars reset or step the zoom of a [WhiteboardView].
class WhiteboardViewController extends ChangeNotifier {
  PageTransform _transform = const PageTransform();
  PageTransform get transform => _transform;
  double get zoom => _transform.scale;

  static const minScale = 0.25;
  static const maxScale = 6.0;

  void _set(PageTransform t) {
    _transform = t;
    notifyListeners();
  }

  void reset() => _set(const PageTransform());

  /// Zooms around [focal] (local coordinates) by [factor].
  void zoomBy(double factor, Offset focal) {
    final scale = (_transform.scale * factor).clamp(minScale, maxScale);
    final applied = scale / _transform.scale;
    _set(
      PageTransform(
        scale: scale,
        offset: focal - (focal - _transform.offset) * applied,
      ),
    );
  }

  void panBy(Offset delta) => _set(
    PageTransform(offset: _transform.offset + delta, scale: _transform.scale),
  );
}

class _WhiteboardViewState extends ConsumerState<WhiteboardView> {
  late WhiteboardViewController _view =
      widget.viewController ?? WhiteboardViewController();

  @override
  void didUpdateWidget(WhiteboardView old) {
    super.didUpdateWidget(old);
    if (widget.viewController != null && widget.viewController != _view) {
      _view = widget.viewController!;
    }
  }

  @override
  void dispose() {
    if (widget.viewController == null) _view.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isMetaPressed) {
      _view.zoomBy(
        event.scrollDelta.dy < 0 ? 1.1 : 1 / 1.1,
        event.localPosition,
      );
    } else {
      _view.panBy(-event.scrollDelta);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(toolSettingsProvider);
    return Listener(
      onPointerSignal: _onPointerSignal,
      onPointerPanZoomUpdate: (e) {
        _view.panBy(e.panDelta);
        if (e.scale != 1) _view.zoomBy(e.scale, e.localPosition);
      },
      child: ListenableBuilder(
        listenable: Listenable.merge([_view, widget.controller]),
        builder: (context, _) {
          final transform = _view.transform;
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: BackgroundPainter(
                  background:
                      widget.controller.page(widget.pageIndex).background,
                  offset: transform.offset,
                  scale: transform.scale,
                ),
              ),
              DrawingSurface(
                controller: widget.controller,
                pageIndex: widget.pageIndex,
                settings: settings,
                transform: transform,
                onTouchPan: _view.panBy,
                onTouchScale: (focal, scale, pan) {
                  _view.panBy(pan);
                  _view.zoomBy(scale, focal);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
