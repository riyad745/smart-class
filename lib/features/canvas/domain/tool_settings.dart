import 'drawing_tool.dart';

/// How pen and finger input are interpreted.
enum InputMode {
  /// Any pointer draws. Two fingers pan/zoom. Best for phones and mouse.
  any,

  /// Only a stylus (Apple Pencil, S Pen, active pen) or mouse draws; fingers
  /// always pan/zoom. This is the palm-rejection mode for tablets.
  stylusOnly,
}

/// The currently selected tool and its style. Shared by the whiteboard and
/// PDF annotation so switching between them keeps the teacher's pen.
class ToolSettings {
  const ToolSettings({
    this.tool = DrawingTool.pen,
    this.color = 0xFF1F2937,
    this.width = 3,
    this.eraserRadius = 14,
    this.inputMode = InputMode.any,
  });

  final DrawingTool tool;
  final int color;
  final double width;
  final double eraserRadius;
  final InputMode inputMode;

  ToolSettings copyWith({
    DrawingTool? tool,
    int? color,
    double? width,
    double? eraserRadius,
    InputMode? inputMode,
  }) => ToolSettings(
    tool: tool ?? this.tool,
    color: color ?? this.color,
    width: width ?? this.width,
    eraserRadius: eraserRadius ?? this.eraserRadius,
    inputMode: inputMode ?? this.inputMode,
  );

  static const palette = <int>[
    0xFF1F2937, // ink
    0xFFFFFFFF, // chalk
    0xFFE53935, // red
    0xFF1E88E5, // blue
    0xFF43A047, // green
    0xFFFDD835, // yellow
    0xFFFB8C00, // orange
    0xFF8E24AA, // purple
  ];

  static const widths = <double>[1.5, 3, 5, 8, 12];
}
