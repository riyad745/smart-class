import 'board_background.dart';
import 'stroke.dart';

/// One page of strokes. Used both for whiteboard pages and for the
/// annotation layer on top of a single PDF page.
///
/// Whiteboard pages use an unbounded coordinate space in logical pixels.
/// PDF annotation pages use the PDF page's own size in points, so strokes
/// stay attached to the content at any zoom level.
class CanvasPage {
  const CanvasPage({
    this.strokes = const [],
    this.background = BoardBackground.whiteboard,
  });

  final List<Stroke> strokes;
  final BoardBackground background;

  bool get isEmpty => strokes.isEmpty;

  CanvasPage copyWith({List<Stroke>? strokes, BoardBackground? background}) =>
      CanvasPage(
        strokes: strokes ?? this.strokes,
        background: background ?? this.background,
      );

  Map<String, dynamic> toJson() => {
    'background': background.name,
    'strokes': strokes.map((s) => s.toJson()).toList(),
  };

  factory CanvasPage.fromJson(Map<String, dynamic> json) => CanvasPage(
    background:
        BoardBackground.values.asNameMap()[json['background']] ??
        BoardBackground.whiteboard,
    strokes:
        (json['strokes'] as List? ?? const [])
            .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
            .toList(),
  );
}

/// A multi-page document of [CanvasPage]s.
///
/// For a whiteboard file, the pages are the board's pages. For a PDF file,
/// the key is the zero-based PDF page index and only annotated pages are
/// stored.
class CanvasDocument {
  const CanvasDocument({this.pages = const {}});

  final Map<int, CanvasPage> pages;

  CanvasPage page(int index) => pages[index] ?? const CanvasPage();

  CanvasDocument withPage(int index, CanvasPage page) =>
      CanvasDocument(pages: {...pages, index: page});

  int get pageCount =>
      pages.isEmpty ? 1 : pages.keys.reduce((a, b) => a > b ? a : b) + 1;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'pages': {
      for (final e in pages.entries)
        if (!e.value.isEmpty ||
            e.value.background != BoardBackground.whiteboard)
          '${e.key}': e.value.toJson(),
    },
  };

  factory CanvasDocument.fromJson(Map<String, dynamic> json) => CanvasDocument(
    pages: {
      for (final e
          in (json['pages'] as Map<String, dynamic>? ?? const {}).entries)
        int.parse(e.key): CanvasPage.fromJson(e.value as Map<String, dynamic>),
    },
  );
}
