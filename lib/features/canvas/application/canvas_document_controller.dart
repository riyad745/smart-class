import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../domain/board_background.dart';
import '../domain/canvas_page.dart';
import '../domain/stroke.dart';
import 'canvas_history.dart';

/// Owns the editable state of one [CanvasDocument] (a whiteboard file or the
/// annotation layer of a PDF) and its undo/redo history.
///
/// The same controller powers the whiteboard and PDF annotation, so drawing
/// behaviour is identical in both. Persistence is injected via [onSave] and
/// debounced, so the UI never waits on disk or network.
class CanvasDocumentController extends ChangeNotifier {
  CanvasDocumentController({
    CanvasDocument initial = const CanvasDocument(),
    this.onSave,
    this.saveDelay = const Duration(milliseconds: 800),
  }) : _history = History(initial);

  final Future<void> Function(CanvasDocument document)? onSave;
  final Duration saveDelay;
  final History<CanvasDocument> _history;
  Timer? _saveTimer;
  CanvasDocument? _eraseBase;

  CanvasDocument get document => _history.current;
  CanvasPage page(int index) => document.page(index);
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  void addStroke(int pageIndex, Stroke stroke) {
    final page = document.page(pageIndex);
    _commit(
      document.withPage(
        pageIndex,
        page.copyWith(strokes: [...page.strokes, stroke]),
      ),
    );
  }

  void setBackground(int pageIndex, BoardBackground background) {
    final page = document.page(pageIndex);
    if (page.background == background) return;
    _commit(
      document.withPage(pageIndex, page.copyWith(background: background)),
    );
  }

  void clearPage(int pageIndex) {
    final page = document.page(pageIndex);
    if (page.isEmpty) return;
    _commit(document.withPage(pageIndex, page.copyWith(strokes: const [])));
  }

  /// Erasing is a continuous gesture that should undo as one step:
  /// call [beginErase], then [eraseAt] for every pointer move, then [endErase].
  void beginErase() => _eraseBase = document;

  void eraseAt(int pageIndex, Offset point, double radius) {
    final page = document.page(pageIndex);
    final remaining =
        page.strokes.where((s) => !s.hitTest(point, radius)).toList();
    if (remaining.length == page.strokes.length) return;
    _history.replace(
      document.withPage(pageIndex, page.copyWith(strokes: remaining)),
    );
    notifyListeners();
  }

  void endErase() {
    final base = _eraseBase;
    _eraseBase = null;
    if (base == null || identical(base, document)) return;
    final erased = document;
    _history.replace(base);
    _commit(erased);
  }

  void undo() {
    if (_history.undo()) _changed();
  }

  void redo() {
    if (_history.redo()) _changed();
  }

  /// Writes pending changes immediately (e.g. when the screen closes).
  Future<void> flush() async {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      await onSave?.call(document);
    }
  }

  void _commit(CanvasDocument next) {
    _history.push(next);
    _changed();
  }

  void _changed() {
    notifyListeners();
    if (onSave == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDelay, () => onSave!(document));
  }

  @override
  void dispose() {
    // Fire-and-forget: the save does not touch this controller's listeners.
    unawaited(flush());
    super.dispose();
  }
}
