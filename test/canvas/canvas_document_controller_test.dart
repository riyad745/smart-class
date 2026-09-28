import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/features/canvas/application/canvas_document_controller.dart';
import 'package:smart_class/features/canvas/domain/board_background.dart';
import 'package:smart_class/features/canvas/domain/canvas_page.dart';
import 'package:smart_class/features/canvas/domain/drawing_tool.dart';
import 'package:smart_class/features/canvas/domain/stroke.dart';

Stroke line(
  String id,
  Offset a,
  Offset b, {
  DrawingTool tool = DrawingTool.pen,
}) => Stroke(
  id: id,
  tool: tool,
  color: 0xFF000000,
  width: 3,
  points: [StrokePoint(a.dx, a.dy), StrokePoint(b.dx, b.dy)],
);

void main() {
  group('CanvasDocumentController', () {
    test('add, undo and redo strokes', () {
      final c = CanvasDocumentController();
      c.addStroke(0, line('a', Offset.zero, const Offset(10, 10)));
      c.addStroke(0, line('b', Offset.zero, const Offset(20, 0)));
      expect(c.page(0).strokes.map((s) => s.id), ['a', 'b']);

      c.undo();
      expect(c.page(0).strokes.map((s) => s.id), ['a']);
      expect(c.canRedo, isTrue);

      c.redo();
      expect(c.page(0).strokes.map((s) => s.id), ['a', 'b']);
      c.dispose();
    });

    test('a new edit clears the redo stack', () {
      final c = CanvasDocumentController();
      c.addStroke(0, line('a', Offset.zero, const Offset(10, 10)));
      c.undo();
      c.addStroke(0, line('b', Offset.zero, const Offset(10, 10)));
      expect(c.canRedo, isFalse);
      c.dispose();
    });

    test('an erase gesture undoes as a single step', () {
      final c = CanvasDocumentController();
      c.addStroke(0, line('a', Offset.zero, const Offset(100, 0)));
      c.addStroke(0, line('b', const Offset(0, 50), const Offset(100, 50)));

      c.beginErase();
      c.eraseAt(0, const Offset(50, 0), 5);
      c.eraseAt(0, const Offset(50, 50), 5);
      c.endErase();
      expect(c.page(0).strokes, isEmpty);

      c.undo();
      expect(c.page(0).strokes.map((s) => s.id), ['a', 'b']);
      c.dispose();
    });

    test('an erase gesture that hits nothing adds no undo step', () {
      final c = CanvasDocumentController();
      c.addStroke(0, line('a', Offset.zero, const Offset(100, 0)));
      c.beginErase();
      c.eraseAt(0, const Offset(500, 500), 5);
      c.endErase();
      c.undo();
      expect(
        c.page(0).strokes,
        isEmpty,
        reason: 'undo should remove the stroke itself',
      );
      c.dispose();
    });

    test('pages are independent', () {
      final c = CanvasDocumentController();
      c.addStroke(2, line('x', Offset.zero, const Offset(1, 1)));
      c.setBackground(1, BoardBackground.blackboard);
      expect(c.page(0).isEmpty, isTrue);
      expect(c.page(2).strokes, hasLength(1));
      expect(c.document.pageCount, 3);
      c.clearPage(2);
      expect(c.page(2).isEmpty, isTrue);
      c.dispose();
    });

    test('saves are debounced and flushed', () async {
      final saved = <CanvasDocument>[];
      final c = CanvasDocumentController(
        onSave: (d) async => saved.add(d),
        saveDelay: const Duration(hours: 1),
      );
      c.addStroke(0, line('a', Offset.zero, const Offset(1, 1)));
      c.addStroke(0, line('b', Offset.zero, const Offset(1, 1)));
      expect(saved, isEmpty);
      await c.flush();
      expect(saved, hasLength(1));
      expect(saved.single.page(0).strokes, hasLength(2));
      c.dispose();
    });
  });

  group('Stroke', () {
    test('JSON round trip', () {
      final doc = const CanvasDocument().withPage(
        3,
        CanvasPage(
          background: BoardBackground.grid,
          strokes: [
            line(
              'a',
              const Offset(1.5, 2.25),
              const Offset(3, 4),
              tool: DrawingTool.arrow,
            ),
          ],
        ),
      );
      final restored = CanvasDocument.fromJson(doc.toJson());
      final page = restored.page(3);
      expect(page.background, BoardBackground.grid);
      expect(page.strokes.single.tool, DrawingTool.arrow);
      expect(page.strokes.single.points.first.x, 1.5);
      expect(page.strokes.single.points.first.y, 2.25);
    });

    test('hit test follows shape outlines, not the bounding box', () {
      final rect = line(
        'r',
        Offset.zero,
        const Offset(100, 100),
        tool: DrawingTool.rectangle,
      );
      expect(
        rect.hitTest(const Offset(50, 0), 4),
        isTrue,
        reason: 'on the top edge',
      );
      expect(
        rect.hitTest(const Offset(50, 50), 4),
        isFalse,
        reason: 'inside, away from edges',
      );
    });
  });
}
