/// Generic undo/redo stack over immutable snapshots.
///
/// Pure Dart with no Flutter dependencies, so it is trivially unit-testable.
/// The canvas models are immutable, so a snapshot is cheap: unchanged pages
/// and strokes are shared between snapshots, not copied.
class History<T> {
  History(this._current, {this.limit = 200});

  final int limit;
  T _current;
  final List<T> _undo = [];
  final List<T> _redo = [];

  T get current => _current;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Records [next] as a new undoable step.
  void push(T next) {
    _undo.add(_current);
    if (_undo.length > limit) _undo.removeAt(0);
    _redo.clear();
    _current = next;
  }

  /// Replaces the current state without creating an undo step. Used for
  /// intermediate states of a continuous gesture (e.g. erasing).
  void replace(T next) => _current = next;

  bool undo() {
    if (!canUndo) return false;
    _redo.add(_current);
    _current = _undo.removeLast();
    return true;
  }

  bool redo() {
    if (!canRedo) return false;
    _undo.add(_current);
    _current = _redo.removeLast();
    return true;
  }
}
