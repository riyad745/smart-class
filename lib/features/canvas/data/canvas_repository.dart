import '../../../core/storage/key_value_store.dart';
import '../domain/canvas_page.dart';

/// Loads and saves the stroke data of whiteboards and PDF annotations,
/// keyed by the owning file's id.
class CanvasRepository {
  CanvasRepository(this._store);

  final KeyValueStore _store;

  static String _key(String fileId) => 'canvas/$fileId';

  Future<CanvasDocument> load(String fileId) async {
    final json = await _store.read(_key(fileId));
    return json == null
        ? const CanvasDocument()
        : CanvasDocument.fromJson(json);
  }

  Future<void> save(String fileId, CanvasDocument document) =>
      _store.write(_key(fileId), document.toJson());

  Future<void> copy(String fromFileId, String toFileId) async {
    final json = await _store.read(_key(fromFileId));
    if (json != null) await _store.write(_key(toFileId), json);
  }

  Future<void> delete(String fileId) => _store.delete(_key(fileId));
}
