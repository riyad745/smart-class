/// Every tool the teacher can pick from the canvas toolbar.
///
/// Freehand tools produce [Stroke]s from the raw pointer path. Shape tools
/// only use the first and last point of the gesture. [laser] strokes are
/// never saved: they fade out a moment after the pointer lifts.
enum DrawingTool {
  pen,
  pencil,
  marker,
  highlighter,
  eraser,
  line,
  arrow,
  rectangle,
  ellipse,
  laser;

  bool get isShape =>
      this == line || this == arrow || this == rectangle || this == ellipse;

  bool get isFreehand =>
      this == pen || this == pencil || this == marker || this == highlighter;

  /// Whether strokes made with this tool become part of the document.
  bool get isPersistent => this != laser && this != eraser;

  /// Opacity applied on top of the chosen colour.
  double get opacity => switch (this) {
    highlighter => 0.35,
    pencil => 0.85,
    _ => 1.0,
  };

  /// Multiplier applied to the base stroke width.
  double get widthFactor => switch (this) {
    marker => 2.0,
    highlighter => 4.0,
    pencil => 0.7,
    _ => 1.0,
  };

  /// Whether stylus pressure changes the stroke width.
  bool get usesPressure => this == pen || this == pencil;
}
