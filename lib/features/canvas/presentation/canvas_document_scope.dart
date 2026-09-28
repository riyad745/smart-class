import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/canvas_document_controller.dart';
import '../application/canvas_providers.dart';

/// Loads the canvas document stored under [documentId], creates a
/// [CanvasDocumentController] that autosaves back to it, and disposes the
/// controller (flushing pending saves) when this widget leaves the tree.
class CanvasDocumentScope extends ConsumerStatefulWidget {
  const CanvasDocumentScope({
    super.key,
    required this.documentId,
    required this.builder,
  });

  final String documentId;
  final Widget Function(
    BuildContext context,
    CanvasDocumentController controller,
  )
  builder;

  @override
  ConsumerState<CanvasDocumentScope> createState() =>
      _CanvasDocumentScopeState();
}

class _CanvasDocumentScopeState extends ConsumerState<CanvasDocumentScope> {
  CanvasDocumentController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(canvasRepositoryProvider);
    try {
      final doc = await repo.load(widget.documentId);
      if (!mounted) return;
      setState(() {
        _controller = CanvasDocumentController(
          initial: doc,
          onSave: (d) => repo.save(widget.documentId, d),
        );
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Text('Could not open: $_error'));
    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return widget.builder(context, controller);
  }
}
