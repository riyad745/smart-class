import 'package:flutter/rendering.dart';

import '../../domain/board_background.dart';

/// Paints the board background for the visible viewport. Pattern lines follow
/// the board's pan/zoom so the paper moves with the ink.
class BackgroundPainter extends CustomPainter {
  const BackgroundPainter({
    required this.background,
    this.offset = Offset.zero,
    this.scale = 1,
  });

  final BoardBackground background;
  final Offset offset;
  final double scale;

  static const _spacing = 32.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Color(background.color),
    );
    final lineColor =
        background.isDark ? const Color(0x22FFFFFF) : const Color(0x33607D8B);
    final paint =
        Paint()
          ..color = lineColor
          ..strokeWidth = 1;
    final step = _spacing * scale;
    if (step < 6) return; // too dense to be useful when zoomed far out
    final startX = offset.dx % step;
    final startY = offset.dy % step;

    switch (background) {
      case BoardBackground.grid:
        for (var x = startX; x < size.width; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        for (var y = startY; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
      case BoardBackground.ruled:
        for (var y = startY; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
      case BoardBackground.dots:
        paint.strokeWidth = 2;
        for (var x = startX; x < size.width; x += step) {
          for (var y = startY; y < size.height; y += step) {
            canvas.drawCircle(Offset(x, y), 1.2, paint);
          }
        }
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter old) =>
      old.background != background ||
      old.offset != offset ||
      old.scale != scale;
}
