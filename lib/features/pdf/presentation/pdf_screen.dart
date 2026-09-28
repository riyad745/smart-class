import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../canvas/application/canvas_document_controller.dart';
import '../../canvas/presentation/canvas_document_scope.dart';
import '../../canvas/presentation/whiteboard_panel.dart';
import '../../canvas/presentation/widgets/canvas_toolbar.dart';
import '../../classroom/application/classroom_tools_provider.dart';
import '../../classroom/presentation/teaching_scaffold.dart';
import '../../files/application/files_providers.dart';
import '../../workspace/presentation/split_view.dart';
import 'pdf_annotator_view.dart';
import 'pdf_search_bar.dart';
import 'pdf_thumbnails.dart';

/// Teaching view for a PDF: annotate directly on the pages, and optionally
/// open a whiteboard next to it (split screen).
class PdfScreen extends ConsumerStatefulWidget {
  const PdfScreen({super.key, required this.fileId});

  final String fileId;

  /// The side whiteboard of a PDF is stored as its own canvas document.
  static String sideBoardId(String pdfId) => '${pdfId}_board';

  @override
  ConsumerState<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends ConsumerState<PdfScreen> {
  final _viewer = PdfViewerController();
  late final _searcher = PdfTextSearcher(_viewer);
  final _annotating = ValueNotifier(true);

  /// Keeps the PDF pane (viewer + ink) alive when toggling split screen.
  final _pdfPaneKey = GlobalKey();
  bool _split = false;
  bool _search = false;
  bool _thumbnails = false;
  bool _ready = false;
  int _page = 1;

  @override
  void dispose() {
    _searcher.dispose();
    _annotating.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = ref.watch(fileByIdProvider(widget.fileId));
    final path = ref.watch(fileRepositoryProvider).pdfFile(widget.fileId).path;
    final showToolbar = ref.watch(
      classroomToolsProvider.select((s) => s.toolbarVisible),
    );

    final pdfPane = CanvasDocumentScope(
      key: _pdfPaneKey,
      documentId: widget.fileId,
      builder:
          (context, ink) => Stack(
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    if (_thumbnails && _ready)
                      PdfThumbnails(
                        document: _viewer.document,
                        currentPage: _page,
                        onSelected: (p) => _viewer.goToPage(pageNumber: p),
                      ),
                    Expanded(
                      child: PdfAnnotatorView(
                        filePath: path,
                        ink: ink,
                        annotating: _annotating,
                        viewerController: _viewer,
                        textSearcher: _searcher,
                        onReady: () => setState(() => _ready = true),
                        onPageChanged: (p) => setState(() => _page = p),
                      ),
                    ),
                  ],
                ),
              ),
              if (_search)
                Positioned(
                  top: 8,
                  right: 8,
                  child: PdfSearchBar(
                    searcher: _searcher,
                    onClose: () => setState(() => _search = false),
                  ),
                ),
              if (showToolbar)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _PdfToolbar(
                      ink: ink,
                      annotating: _annotating,
                      page: _page,
                      pageCount: _ready ? _viewer.pageCount : null,
                      viewer: _viewer,
                    ),
                  ),
                ),
            ],
          ),
    );

    return TeachingScaffold(
      title: file?.name ?? 'PDF',
      actions: [
        IconButton(
          tooltip: 'Search',
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _search = !_search),
        ),
        IconButton(
          tooltip: 'Page thumbnails',
          isSelected: _thumbnails,
          icon: const Icon(Icons.view_sidebar_outlined),
          onPressed: () => setState(() => _thumbnails = !_thumbnails),
        ),
        IconButton(
          tooltip: _split ? 'Close whiteboard' : 'Open whiteboard beside PDF',
          isSelected: _split,
          icon: const Icon(Icons.vertical_split_outlined),
          onPressed: () => setState(() => _split = !_split),
        ),
      ],
      body:
          _split
              ? SplitView(
                first: pdfPane,
                second: CanvasDocumentScope(
                  documentId: PdfScreen.sideBoardId(widget.fileId),
                  builder:
                      (context, board) => WhiteboardPanel(
                        controller: board,
                        showToolbar: showToolbar,
                      ),
                ),
              )
              : pdfPane,
    );
  }
}

class _PdfToolbar extends StatelessWidget {
  const _PdfToolbar({
    required this.ink,
    required this.annotating,
    required this.page,
    required this.pageCount,
    required this.viewer,
  });

  final CanvasDocumentController ink;
  final ValueNotifier<bool> annotating;
  final int page;
  final int? pageCount;
  final PdfViewerController viewer;

  @override
  Widget build(BuildContext context) {
    final navigation = [
      IconButton(
        tooltip: 'Previous page',
        icon: const Icon(Icons.keyboard_arrow_up),
        onPressed:
            page > 1 ? () => viewer.goToPage(pageNumber: page - 1) : null,
      ),
      Text(pageCount == null ? '–' : '$page / $pageCount'),
      IconButton(
        tooltip: 'Next page',
        icon: const Icon(Icons.keyboard_arrow_down),
        onPressed:
            pageCount != null && page < pageCount!
                ? () => viewer.goToPage(pageNumber: page + 1)
                : null,
      ),
      IconButton(
        tooltip: 'Zoom out',
        icon: const Icon(Icons.zoom_out),
        onPressed: pageCount == null ? null : () => viewer.zoomDown(),
      ),
      IconButton(
        tooltip: 'Zoom in',
        icon: const Icon(Icons.zoom_in),
        onPressed: pageCount == null ? null : () => viewer.zoomUp(),
      ),
    ];

    return ValueListenableBuilder<bool>(
      valueListenable: annotating,
      builder: (context, active, _) {
        final toggle = IconButton.filledTonal(
          tooltip:
              active ? 'Stop annotating (scroll & select text)' : 'Annotate',
          isSelected: active,
          icon: const Icon(Icons.pan_tool_outlined),
          selectedIcon: const Icon(Icons.draw),
          onPressed: () => annotating.value = !active,
        );
        if (!active) {
          return Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [toggle, ...navigation],
              ),
            ),
          );
        }
        return CanvasToolbar(
          controller: ink,
          onClear: () => ink.clearPage(page - 1),
          leading: [toggle],
          trailing: navigation,
        );
      },
    );
  }
}
