import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../core/utils/id.dart';
import '../application/canvas_document_controller.dart';
import '../domain/drawing_tool.dart';
import '../domain/stroke.dart';
import '../domain/tool_settings.dart';
import 'painters/stroke_renderer.dart';

/// Maps between widget-local coordinates and page coordinates:
/// `local = offset + page * scale`.
@immutable
class PageTransform {
  const PageTransform({this.offset = Offset.zero, this.scale = 1});

  final Offset offset;
  final double scale;

  Offset toPage(Offset local) => (local - offset) / scale;

  @override
  bool operator ==(Object other) =>
      other is PageTransform && other.offset == offset && other.scale == scale;

  @override
  int get hashCode => Object.hash(offset, scale);
}

/// The interactive ink layer shared by the whiteboard and the PDF annotator.
///
/// Input rules (see docs/ARCHITECTURE.md → "Stylus & touch"):
/// * Stylus and mouse always draw. The stylus' back end (inverted stylus)
///   always erases.
/// * Touch draws only in [InputMode.any]; in [InputMode.stylusOnly] touches
///   are reported through [onTouchPan]/[onTouchScale] instead (palm
///   rejection).
/// * A second finger landing mid-stroke cancels the stroke and becomes a
///   pan/zoom gesture.
/// * Pressure is used where the device reports it; otherwise a constant
///   mid pressure is recorded (graceful fallback).
class DrawingSurface extends StatefulWidget {
  const DrawingSurface({
    super.key,
    required this.controller,
    required this.pageIndex,
    required this.settings,
    this.transform = const PageTransform(),
    this.onTouchPan,
    this.onTouchScale,
    this.onTouchGestureEnd,
    this.claimPointers = false,
  });

  final CanvasDocumentController controller;
  final int pageIndex;
  final ToolSettings settings;
  final PageTransform transform;

  /// Single-finger drag that is not drawing (delta in local pixels).
  final ValueChanged<Offset>? onTouchPan;

  /// Two-finger pinch: focal point (local) and incremental scale factor.
  final void Function(Offset focal, double scaleDelta, Offset panDelta)?
  onTouchScale;
  final VoidCallback? onTouchGestureEnd;

  /// When the surface sits inside another scrollable (e.g. a PDF viewer),
  /// set this so drawing pointers win the gesture arena and the page does
  /// not scroll while writing.
  final bool claimPointers;

  @override
  State<DrawingSurface> createState() => _DrawingSurfaceState();
}

class _FadingStroke {
  _FadingStroke(this.stroke, this.releasedAt);
  final Stroke stroke;
  final Duration releasedAt;
}

class _DrawingSurfaceState extends State<DrawingSurface>
    with SingleTickerProviderStateMixin {
  static const _laserFade = Duration(milliseconds: 1200);

  int? _drawPointer;
  bool _erasing = false;
  Offset? _eraserPosition;
  List<StrokePoint> _activePoints = [];
  DrawingTool? _activeTool;

  final Map<int, Offset> _touches = {};
  final List<_FadingStroke> _laser = [];
  late final Ticker _ticker = createTicker(_onTick);
  Duration _now = Duration.zero;

  ToolSettings get _settings => widget.settings;

  bool _isDrawingPointer(PointerDownEvent e) => switch (e.kind) {
    PointerDeviceKind.stylus || PointerDeviceKind.invertedStylus => true,
    PointerDeviceKind.mouse => e.buttons == kPrimaryMouseButton,
    PointerDeviceKind.touch => _settings.inputMode == InputMode.any,
    _ => false,
  };

  Set<PointerDeviceKind> get _drawingDevices => {
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.mouse,
    if (_settings.inputMode == InputMode.any) PointerDeviceKind.touch,
  };

  // --- pointer handling ----------------------------------------------------

  void _onDown(PointerDownEvent e) {
    if (e.kind == PointerDeviceKind.touch) {
      _touches[e.pointer] = e.localPosition;
      // Second finger while a finger stroke is active → it was a gesture.
      if (_touches.length > 1 &&
          _drawPointer != null &&
          _touches.containsKey(_drawPointer)) {
        _cancelStroke();
      }
      if (_touches.length > 1 || !_isDrawingPointer(e)) return;
    }
    if (_drawPointer != null || !_isDrawingPointer(e)) return;

    _drawPointer = e.pointer;
    final tool =
        e.kind == PointerDeviceKind.invertedStylus
            ? DrawingTool.eraser
            : _settings.tool;
    _activeTool = tool;
    if (tool == DrawingTool.eraser) {
      _erasing = true;
      widget.controller.beginErase();
      _eraseAt(e.localPosition);
    } else {
      setState(() => _activePoints = [_point(e)]);
    }
  }

  void _onMove(PointerMoveEvent e) {
    if (_touches.containsKey(e.pointer) && e.pointer != _drawPointer) {
      _handleTouchGesture(e);
      return;
    }
    if (e.pointer != _drawPointer) return;
    if (_touches.containsKey(e.pointer)) _touches[e.pointer] = e.localPosition;
    if (_erasing) {
      _eraseAt(e.localPosition);
      return;
    }
    final point = _point(e);
    setState(() {
      if (_activeTool!.isShape) {
        _activePoints = [_activePoints.first, point];
      } else {
        _activePoints = [..._activePoints, point];
      }
    });
  }

  void _onUp(PointerEvent e) {
    final wasTouch = _touches.remove(e.pointer) != null;
    if (wasTouch && _touches.isEmpty) widget.onTouchGestureEnd?.call();
    if (e.pointer != _drawPointer) return;
    if (e is PointerCancelEvent) {
      _cancelStroke();
      return;
    }
    _finishStroke();
  }

  void _handleTouchGesture(PointerMoveEvent e) {
    final previous = Map<int, Offset>.of(_touches);
    _touches[e.pointer] = e.localPosition;
    if (_touches.length == 1) {
      widget.onTouchPan?.call(e.localDelta);
    } else if (_touches.length >= 2) {
      final ids = _touches.keys.take(2).toList();
      final a0 = previous[ids[0]]!, b0 = previous[ids[1]]!;
      final a1 = _touches[ids[0]]!, b1 = _touches[ids[1]]!;
      final d0 = (a0 - b0).distance;
      final d1 = (a1 - b1).distance;
      final focal = (a1 + b1) / 2;
      final panDelta = focal - (a0 + b0) / 2;
      widget.onTouchScale?.call(focal, d0 == 0 ? 1 : d1 / d0, panDelta);
    }
  }

  StrokePoint _point(PointerEvent e) {
    final page = widget.transform.toPage(e.localPosition);
    // pressureMin == pressureMax means the device has no pressure sensor.
    final hasPressure =
        e.pressureMax > e.pressureMin &&
        e.kind != PointerDeviceKind.mouse &&
        e.kind != PointerDeviceKind.touch;
    final pressure =
        hasPressure
            ? ((e.pressure - e.pressureMin) / (e.pressureMax - e.pressureMin))
                .clamp(0.0, 1.0)
            : 0.5;
    return StrokePoint(page.dx, page.dy, pressure);
  }

  void _eraseAt(Offset local) {
    setState(() => _eraserPosition = local);
    widget.controller.eraseAt(
      widget.pageIndex,
      widget.transform.toPage(local),
      _settings.eraserRadius / widget.transform.scale,
    );
  }

  void _finishStroke() {
    if (_erasing) {
      widget.controller.endErase();
    } else if (_activePoints.isNotEmpty && _activeTool != null) {
      final stroke = Stroke(
        id: newId(),
        tool: _activeTool!,
        color: _activeTool == DrawingTool.laser ? 0xFFFF1744 : _settings.color,
        width: _settings.width,
        points: _activePoints,
      );
      if (_activeTool == DrawingTool.laser) {
        _laser.add(_FadingStroke(stroke, _now));
        if (!_ticker.isActive) _ticker.start();
      } else if (!_activeTool!.isShape || _activePoints.length > 1) {
        widget.controller.addStroke(widget.pageIndex, stroke);
      }
    }
    _reset();
  }

  void _cancelStroke() {
    if (_erasing) widget.controller.endErase();
    _reset();
  }

  void _reset() {
    setState(() {
      _drawPointer = null;
      _erasing = false;
      _eraserPosition = null;
      _activePoints = [];
      _activeTool = null;
    });
  }

  void _onTick(Duration elapsed) {
    _now = elapsed;
    setState(
      () => _laser.removeWhere((s) => elapsed - s.releasedAt > _laserFade),
    );
    if (_laser.isEmpty && _activeTool != DrawingTool.laser) {
      _ticker.stop();
      _now = Duration.zero;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // --- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    Widget surface = Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onUp,
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: ListenableBuilder(
                listenable: widget.controller,
                builder:
                    (context, _) => CustomPaint(
                      painter: _StrokesPainter(
                        strokes:
                            widget.controller.page(widget.pageIndex).strokes,
                        transform: widget.transform,
                      ),
                    ),
              ),
            ),
            CustomPaint(
              painter: _ActivePainter(
                active:
                    _activePoints.isEmpty || _activeTool == null
                        ? null
                        : Stroke(
                          id: '',
                          tool: _activeTool!,
                          color: _settings.color,
                          width: _settings.width,
                          points: _activePoints,
                        ),
                laser: [
                  for (final s in _laser)
                    (
                      s.stroke,
                      1 -
                          ((_now - s.releasedAt).inMilliseconds /
                                  _laserFade.inMilliseconds)
                              .clamp(0.0, 1.0),
                    ),
                ],
                eraser: _eraserPosition,
                eraserRadius: _settings.eraserRadius,
                transform: widget.transform,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.claimPointers) {
      surface = RawGestureDetector(
        // Recreate the recognizer when the set of drawing devices changes.
        key: ValueKey(_settings.inputMode),
        behavior: HitTestBehavior.opaque,
        gestures: {
          EagerGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                () => EagerGestureRecognizer(supportedDevices: _drawingDevices),
                (_) {},
              ),
        },
        child: surface,
      );
    }
    return surface;
  }
}

class _StrokesPainter extends CustomPainter {
  _StrokesPainter({required this.strokes, required this.transform});

  final List<Stroke> strokes;
  final PageTransform transform;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(transform.offset.dx, transform.offset.dy);
    canvas.scale(transform.scale);
    StrokeRenderer.paintAll(canvas, strokes);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StrokesPainter old) =>
      !identical(old.strokes, strokes) || old.transform != transform;
}

class _ActivePainter extends CustomPainter {
  _ActivePainter({
    required this.active,
    required this.laser,
    required this.eraser,
    required this.eraserRadius,
    required this.transform,
  });

  final Stroke? active;
  final List<(Stroke, double)> laser;
  final Offset? eraser;
  final double eraserRadius;
  final PageTransform transform;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(transform.offset.dx, transform.offset.dy);
    canvas.scale(transform.scale);
    for (final (stroke, opacity) in laser) {
      StrokeRenderer.paintLaser(canvas, stroke, opacity);
    }
    final a = active;
    if (a != null) {
      if (a.tool == DrawingTool.laser) {
        StrokeRenderer.paintLaser(canvas, a, 1);
      } else {
        StrokeRenderer.paint(canvas, a);
      }
    }
    canvas.restore();
    if (eraser != null) {
      canvas.drawCircle(
        eraser!,
        eraserRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xAA888888),
      );
    }
  }

  @override
  bool shouldRepaint(_ActivePainter old) => true;
}
