import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/features/canvas/application/canvas_document_controller.dart';
import 'package:smart_class/features/canvas/domain/drawing_tool.dart';
import 'package:smart_class/features/canvas/domain/tool_settings.dart';
import 'package:smart_class/features/canvas/presentation/drawing_surface.dart';

void main() {
  Future<CanvasDocumentController> pumpSurface(
    WidgetTester tester,
    ToolSettings settings, {
    PageTransform transform = const PageTransform(),
    ValueChanged<Offset>? onTouchPan,
  }) async {
    final controller = CanvasDocumentController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DrawingSurface(
          controller: controller,
          pageIndex: 0,
          settings: settings,
          transform: transform,
          onTouchPan: onTouchPan,
        ),
      ),
    );
    return controller;
  }

  Future<void> drag(
    WidgetTester tester,
    PointerDeviceKind kind, {
    Offset from = const Offset(100, 100),
  }) async {
    final gesture = await tester.startGesture(from, kind: kind);
    await gesture.moveBy(const Offset(40, 0));
    await gesture.moveBy(const Offset(40, 20));
    await gesture.up();
    await tester.pump();
  }

  testWidgets('stylus draws a stroke in page coordinates', (tester) async {
    final c = await pumpSurface(
      tester,
      const ToolSettings(),
      transform: const PageTransform(offset: Offset(100, 100), scale: 2),
    );
    await drag(tester, PointerDeviceKind.stylus);
    final stroke = c.page(0).strokes.single;
    expect(stroke.tool, DrawingTool.pen);
    expect(stroke.points.first.offset, Offset.zero);
    expect(stroke.points.last.offset, const Offset(40, 10));
  });

  testWidgets('finger draws in "any" mode', (tester) async {
    final c = await pumpSurface(tester, const ToolSettings());
    await drag(tester, PointerDeviceKind.touch);
    expect(c.page(0).strokes, hasLength(1));
  });

  testWidgets(
    'palm rejection: finger pans instead of drawing in stylus-only mode',
    (tester) async {
      var panned = Offset.zero;
      final c = await pumpSurface(
        tester,
        const ToolSettings(inputMode: InputMode.stylusOnly),
        onTouchPan: (d) => panned += d,
      );
      await drag(tester, PointerDeviceKind.touch);
      expect(c.page(0).strokes, isEmpty);
      expect(panned, isNot(Offset.zero));

      await drag(tester, PointerDeviceKind.stylus);
      expect(c.page(0).strokes, hasLength(1));
    },
  );

  testWidgets('shape tools keep only start and end points', (tester) async {
    final c = await pumpSurface(
      tester,
      const ToolSettings(tool: DrawingTool.rectangle),
    );
    await drag(tester, PointerDeviceKind.mouse);
    expect(c.page(0).strokes.single.points, hasLength(2));
  });

  testWidgets('laser strokes are never saved', (tester) async {
    final c = await pumpSurface(
      tester,
      const ToolSettings(tool: DrawingTool.laser),
    );
    await drag(tester, PointerDeviceKind.stylus);
    expect(c.page(0).strokes, isEmpty);
    await tester.pump(const Duration(seconds: 2)); // let the fade finish
  });

  testWidgets('eraser removes strokes it touches', (tester) async {
    final c = await pumpSurface(tester, const ToolSettings());
    await drag(tester, PointerDeviceKind.stylus);
    expect(c.page(0).strokes, hasLength(1));

    // The back end of the stylus erases regardless of the selected tool.
    await drag(
      tester,
      PointerDeviceKind.invertedStylus,
      from: const Offset(80, 100),
    );
    expect(c.page(0).strokes, isEmpty);
    c.undo();
    expect(c.page(0).strokes, hasLength(1));
  });
}
