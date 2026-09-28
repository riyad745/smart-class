import 'dart:math' as math;
import 'dart:ui';

import '../../domain/drawing_tool.dart';
import '../../domain/stroke.dart';

/// Draws [Stroke]s onto a [Canvas]. Stateless, so the whiteboard, the PDF
/// annotation layer and image export all share exactly the same rendering.
abstract final class StrokeRenderer {
  static void paintAll(Canvas canvas, Iterable<Stroke> strokes) {
    for (final stroke in strokes) {
      paint(canvas, stroke);
    }
  }

  static void paint(Canvas canvas, Stroke stroke, {double opacity = 1}) {
    if (stroke.points.isEmpty) return;
    final tool = stroke.tool;
    final color = Color(stroke.color);
    final paint =
        Paint()
          ..color = color.withValues(alpha: color.a * tool.opacity * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke.width * tool.widthFactor
          ..strokeCap =
              tool == DrawingTool.highlighter
                  ? StrokeCap.square
                  : StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true;

    if (tool.isShape) {
      _paintShape(canvas, stroke, paint);
    } else if (tool.usesPressure && _hasPressureVariation(stroke.points)) {
      _paintPressure(canvas, stroke.points, paint);
    } else {
      _paintSmooth(canvas, stroke.points, paint);
    }
  }

  /// Laser strokes: a bright core with a soft glow.
  static void paintLaser(Canvas canvas, Stroke stroke, double opacity) {
    if (stroke.points.isEmpty) return;
    final glow =
        Paint()
          ..color = Color(stroke.color).withValues(alpha: 0.35 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke.width * 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final core =
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    _paintSmooth(canvas, stroke.points, glow);
    _paintSmooth(canvas, stroke.points, core);
  }

  static bool _hasPressureVariation(List<StrokePoint> points) {
    final first = points.first.pressure;
    return points.any((p) => (p.pressure - first).abs() > 0.02);
  }

  /// Quadratic smoothing through segment midpoints: removes the jagged look
  /// of raw pointer samples without lagging behind the pen.
  static void _paintSmooth(
    Canvas canvas,
    List<StrokePoint> points,
    Paint paint,
  ) {
    if (points.length == 1) {
      canvas.drawCircle(
        points.first.offset,
        paint.strokeWidth / 2,
        Paint()..color = paint.color,
      );
      return;
    }
    final path = Path()..moveTo(points.first.x, points.first.y);
    for (var i = 1; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      path.quadraticBezierTo(p0.x, p0.y, (p0.x + p1.x) / 2, (p0.y + p1.y) / 2);
    }
    path.lineTo(points.last.x, points.last.y);
    canvas.drawPath(path, paint);
  }

  /// Pressure-sensitive: each segment's width follows the stylus pressure.
  static void _paintPressure(
    Canvas canvas,
    List<StrokePoint> points,
    Paint paint,
  ) {
    final base = paint.strokeWidth;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final pressure = (a.pressure + b.pressure) / 2;
      paint.strokeWidth = base * (0.35 + pressure * 1.3);
      canvas.drawLine(a.offset, b.offset, paint);
    }
    paint.strokeWidth = base;
  }

  static void _paintShape(Canvas canvas, Stroke stroke, Paint paint) {
    final a = stroke.points.first.offset;
    final b = stroke.points.last.offset;
    switch (stroke.tool) {
      case DrawingTool.rectangle:
        canvas.drawRect(Rect.fromPoints(a, b), paint);
      case DrawingTool.ellipse:
        canvas.drawOval(Rect.fromPoints(a, b), paint);
      case DrawingTool.arrow:
        canvas.drawLine(a, b, paint);
        final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
        final head = math.max(12.0, paint.strokeWidth * 4);
        for (final side in [-1, 1]) {
          final theta = angle + math.pi + side * math.pi / 7;
          canvas.drawLine(
            b,
            b + Offset(math.cos(theta), math.sin(theta)) * head,
            paint,
          );
        }
      default:
        canvas.drawLine(a, b, paint);
    }
  }
}
