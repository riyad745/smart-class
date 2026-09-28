import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Minimal async JSON document store.
///
/// Repositories depend on this interface, never on the file system directly,
/// so they can be tested with [InMemoryKeyValueStore] and later backed by a
/// different engine without touching feature code.
abstract interface class KeyValueStore {
  Future<Map<String, dynamic>?> read(String key);
  Future<void> write(String key, Map<String, dynamic> value);
  Future<void> delete(String key);
}

/// Stores each key as `<root>/<key>.json`. Writes go to a temp file first and
/// are then renamed, so a crash mid-write never corrupts existing data.
class FileKeyValueStore implements KeyValueStore {
  FileKeyValueStore(this.root);

  final Directory root;

  File _file(String key) => File(p.join(root.path, '$key.json'));

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final file = _file(key);
    if (!await file.exists()) return null;
    final text = await file.readAsString();
    if (text.isEmpty) return null;
    return jsonDecode(text) as Map<String, dynamic>;
  }

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    final file = _file(key);
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(value), flush: true);
    await tmp.rename(file.path);
  }

  @override
  Future<void> delete(String key) async {
    final file = _file(key);
    if (await file.exists()) await file.delete();
  }
}

class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _data = {};

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final v = _data[key];
    return v == null ? null : jsonDecode(v) as Map<String, dynamic>;
  }

  @override
  Future<void> write(String key, Map<String, dynamic> value) async =>
      _data[key] = jsonEncode(value);

  @override
  Future<void> delete(String key) async => _data.remove(key);
}
