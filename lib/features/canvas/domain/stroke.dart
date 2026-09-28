import 'dart:math' as math;
import 'dart:ui';

import 'drawing_tool.dart';

/// A single sampled point of a stroke.
///
/// [pressure] is normalised to 0..1. Devices without pressure support
/// report 0.5 so strokes still look natural (graceful fallback).
class StrokePoint {
  const StrokePoint(this.x, this.y, [this.pressure = 0.5]);

  final double x;
  final double y;
  final double pressure;

  Offset get offset => Offset(x, y);

  List<double> toJson() => [_round(x), _round(y), _round(pressure)];

  factory StrokePoint.fromJson(List<dynamic> json) => StrokePoint(
    (json[0] as num).toDouble(),
    (json[1] as num).toDouble(),
    json.length > 2 ? (json[2] as num).toDouble() : 0.5,
  );

  static double _round(double v) => (v * 1000).roundToDouble() / 1000;
}

/// Immutable drawing element on a canvas page or a PDF page.
///
/// Coordinates live in the page's own coordinate space (see
/// `CanvasPage.coordinateSpace`), so a stroke renders identically regardless
/// of zoom level or screen size.
class Stroke {
  const Stroke({
    required this.id,
    required this.tool,
    required this.color,
    required this.width,
    required this.points,
  });

  final String id;
  final DrawingTool tool;

  /// ARGB colour value.
  final int color;

  /// Base width in page units.
  final double width;
  final List<StrokePoint> points;

  Stroke copyWith({List<StrokePoint>? points}) => Stroke(
    id: id,
    tool: tool,
    color: color,
    width: width,
    points: points ?? this.points,
  );

  Rect get bounds {
    if (points.isEmpty) return Rect.zero;
    var minX = points.first.x, maxX = minX;
    var minY = points.first.y, maxY = minY;
    for (final p in points) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }
    return Rect.fromLTRB(
      minX,
      minY,
      maxX,
      maxY,
    ).inflate(width * tool.widthFactor);
  }

  /// True when [point] is within [radius] of any segment of this stroke.
  /// Used by the stroke eraser.
  bool hitTest(Offset point, double radius) {
    if (!bounds.inflate(radius).contains(point)) return false;
    final pts =
        tool.isShape ? _shapeOutline() : points.map((p) => p.offset).toList();
    if (pts.length == 1) return (pts.first - point).distance <= radius;
    final tolerance = radius + width * tool.widthFactor / 2;
    for (var i = 0; i < pts.length - 1; i++) {
      if (_distanceToSegment(point, pts[i], pts[i + 1]) <= tolerance) {
        return true;
      }
    }
    return false;
  }

  List<Offset> _shapeOutline() {
    if (points.isEmpty) return const [];
    final a = points.first.offset;
    final b = points.last.offset;
    switch (tool) {
      case DrawingTool.rectangle:
        return [a, Offset(b.dx, a.dy), b, Offset(a.dx, b.dy), a];
      case DrawingTool.ellipse:
        final rect = Rect.fromPoints(a, b);
        return List.generate(33, (i) {
          final t = i / 32 * 2 * math.pi;
          return Offset(
            rect.center.dx + rect.width / 2 * math.cos(t),
            rect.center.dy + rect.height / 2 * math.sin(t),
          );
        });
      default:
        return [a, b];
    }
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lengthSquared = ab.distanceSquared;
    if (lengthSquared == 0) return (p - a).distance;
    final t = (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / lengthSquared)
        .clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tool': tool.name,
    'color': color,
    'width': width,
    'points': points.map((p) => p.toJson()).toList(),
  };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
    id: json['id'] as String,
    tool: DrawingTool.values.byName(json['tool'] as String),
    color: json['color'] as int,
    width: (json['width'] as num).toDouble(),
    points:
        (json['points'] as List)
            .map((p) => StrokePoint.fromJson(p as List))
            .toList(),
  );
}
