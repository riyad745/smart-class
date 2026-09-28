import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../canvas/application/canvas_document_controller.dart';
import '../../canvas/application/canvas_providers.dart';
import '../../canvas/presentation/drawing_surface.dart';

/// PDF viewer with a per-page ink layer on top.
///
/// Strokes are stored in PDF page coordinates (points), so annotations stay
/// glued to the content at any zoom level and on any screen size. When
/// [annotating] is false the ink is display-only and the viewer handles all
/// gestures (scroll, zoom, text selection, links).
class PdfAnnotatorView extends StatelessWidget {
  const PdfAnnotatorView({
    super.key,
    required this.filePath,
    required this.ink,
    required this.annotating,
    required this.viewerController,
    this.textSearcher,
    this.onPageChanged,
    this.onReady,
  });

  final String filePath;
  final CanvasDocumentController ink;
  final ValueListenable<bool> annotating;
  final PdfViewerController viewerController;
  final PdfTextSearcher? textSearcher;
  final ValueChanged<int>? onPageChanged;
  final VoidCallback? onReady;

  @override
  Widget build(BuildContext context) {
    final searcher = textSearcher;
    return PdfViewer.file(
      filePath,
      controller: viewerController,
      params: PdfViewerParams(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        margin: 12,
        onViewerReady: (_, _) => onReady?.call(),
        onPageChanged: (page) {
          if (page != null) onPageChanged?.call(page);
        },
        pagePaintCallbacks: [
          if (searcher != null) searcher.pageTextMatchPaintCallback,
        ],
        pageOverlaysBuilder:
            (context, pageRect, page) => [
              Positioned.fill(
                child: _PageInkLayer(
                  ink: ink,
                  pageIndex: page.pageNumber - 1,
                  scale: pageRect.width / page.width,
                  annotating: annotating,
                ),
              ),
            ],
      ),
    );
  }
}

class _PageInkLayer extends ConsumerWidget {
  const _PageInkLayer({
    required this.ink,
    required this.pageIndex,
    required this.scale,
    required this.annotating,
  });

  final CanvasDocumentController ink;
  final int pageIndex;
  final double scale;
  final ValueListenable<bool> annotating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(toolSettingsProvider);
    return ValueListenableBuilder<bool>(
      valueListenable: annotating,
      builder:
          (context, active, _) => IgnorePointer(
            ignoring: !active,
            child: DrawingSurface(
              controller: ink,
              pageIndex: pageIndex,
              settings: settings,
              transform: PageTransform(scale: scale),
              // Win the gesture arena against the viewer so the page does not
              // scroll while writing. Fingers still scroll in stylus-only mode.
              claimPointers: true,
            ),
          ),
    );
  }
}
