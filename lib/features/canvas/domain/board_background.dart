/// Background styles for a whiteboard page.
enum BoardBackground {
  whiteboard(0xFFFFFFFF, 0xFF1F2937, 'Whiteboard'),
  blackboard(0xFF1E1E1E, 0xFFFFFFFF, 'Blackboard'),
  greenboard(0xFF1F4D3A, 0xFFFFFFFF, 'Greenboard'),
  grid(0xFFFFFFFF, 0xFF1F2937, 'Grid paper'),
  ruled(0xFFFFFDF5, 0xFF1F2937, 'Ruled paper'),
  dots(0xFFFFFFFF, 0xFF1F2937, 'Dot paper');

  const BoardBackground(this.color, this.defaultInkColor, this.label);

  /// ARGB fill colour.
  final int color;

  /// Ink colour that reads well on this background, used as the default pen.
  final int defaultInkColor;
  final String label;

  bool get isDark => this == blackboard || this == greenboard;
}
