import 'dart:io';

import 'package:path/path.dart' as p;

/// Stores binary files (imported PDFs, exported images) by id.
///
/// Kept separate from [KeyValueStore] because blobs are large and, once cloud
/// sync is added, are uploaded to object storage rather than a database.
abstract interface class BlobStore {
  /// Copies [source] into the store under [id] and returns its size in bytes.
  Future<int> put(String id, File source);
  Future<void> copy(String fromId, String toId);
  File fileFor(String id);
  Future<void> delete(String id);
}

class FileBlobStore implements BlobStore {
  FileBlobStore(this.root);

  final Directory root;

  @override
  File fileFor(String id) => File(p.join(root.path, id));

  @override
  Future<int> put(String id, File source) async {
    await root.create(recursive: true);
    final copied = await source.copy(fileFor(id).path);
    return copied.length();
  }

  @override
  Future<void> copy(String fromId, String toId) async {
    final from = fileFor(fromId);
    if (await from.exists()) await from.copy(fileFor(toId).path);
  }

  @override
  Future<void> delete(String id) async {
    final file = fileFor(id);
    if (await file.exists()) await file.delete();
  }
}
