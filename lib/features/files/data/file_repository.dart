import 'dart:io';

import '../../../core/storage/blob_store.dart';
import '../../../core/storage/key_value_store.dart';
import '../../../core/utils/id.dart';
import '../../canvas/data/canvas_repository.dart';
import '../domain/file_node.dart';

/// Thrown for invalid file operations (e.g. moving a folder into itself).
class FileOperationException implements Exception {
  FileOperationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Local-first repository for the "My Files" tree.
///
/// The whole index is small (metadata only), so it is held in memory and
/// written as a single document after every change. PDF bytes live in the
/// [BlobStore] and strokes in the [CanvasRepository].
///
/// A future cloud implementation keeps this API and syncs the same flat
/// [FileNode] rows; see docs/ARCHITECTURE.md.
class FileRepository {
  FileRepository({
    required KeyValueStore store,
    required BlobStore blobs,
    required CanvasRepository canvases,
    DateTime Function()? clock,
  }) : _store = store,
       _blobs = blobs,
       _canvases = canvases,
       _clock = clock ?? DateTime.now;

  static const _indexKey = 'files_index';

  final KeyValueStore _store;
  final BlobStore _blobs;
  final CanvasRepository _canvases;
  final DateTime Function() _clock;
  Map<String, FileNode>? _nodes;

  Future<List<FileNode>> loadAll() async => (await _load()).values.toList();

  File pdfFile(String fileId) => _blobs.fileFor(fileId);

  Future<FileNode> createFolder(String name, {String? parentId}) =>
      _create(name, FileNodeType.folder, parentId);

  Future<FileNode> createBoard(String name, {String? parentId}) =>
      _create(name, FileNodeType.board, parentId);

  Future<FileNode> importPdf(
    File source,
    String name, {
    String? parentId,
  }) async {
    final id = newId();
    final size = await _blobs.put(id, source);
    return _create(name, FileNodeType.pdf, parentId, id: id, sizeBytes: size);
  }

  Future<void> rename(String id, String name) => _update(
    id,
    (n) => n.copyWith(name: _validName(name), updatedAt: _clock()),
  );

  Future<void> toggleFavorite(String id) =>
      _update(id, (n) => n.copyWith(isFavorite: !n.isFavorite));

  Future<void> markOpened(String id) =>
      _update(id, (n) => n.copyWith(lastOpenedAt: _clock()));

  Future<void> move(String id, String? newParentId) async {
    final nodes = await _load();
    if (newParentId != null) {
      final target = nodes[newParentId];
      if (target == null || !target.isFolder) {
        throw FileOperationException('Destination is not a folder.');
      }
      if (newParentId == id || _isDescendant(nodes, newParentId, of: id)) {
        throw FileOperationException('A folder cannot be moved into itself.');
      }
    }
    await _update(
      id,
      (n) => n.copyWith(parentId: newParentId, updatedAt: _clock()),
    );
  }

  /// Copies a file, or a folder with everything inside it.
  Future<FileNode> duplicate(String id) async {
    final nodes = await _load();
    final source = _require(nodes, id);
    final copy = await _duplicateInto(
      nodes,
      source,
      source.parentId,
      '${source.name} (copy)',
    );
    await _persist();
    return copy;
  }

  /// Deletes a node and, for folders, everything inside it.
  Future<void> delete(String id) async {
    final nodes = await _load();
    final ids = [id, ..._descendantIds(nodes, id)];
    for (final nodeId in ids) {
      final node = nodes.remove(nodeId);
      if (node == null) continue;
      if (node.type == FileNodeType.pdf) await _blobs.delete(nodeId);
      if (!node.isFolder) await _canvases.delete(nodeId);
    }
    await _persist();
  }

  // --- internals -----------------------------------------------------------

  Future<Map<String, FileNode>> _load() async {
    if (_nodes != null) return _nodes!;
    final json = await _store.read(_indexKey);
    final list = (json?['nodes'] as List?) ?? const [];
    return _nodes = {
      for (final item in list)
        (item as Map<String, dynamic>)['id'] as String: FileNode.fromJson(item),
    };
  }

  Future<void> _persist() => _store.write(_indexKey, {
    'version': 1,
    'nodes': _nodes!.values.map((n) => n.toJson()).toList(),
  });

  Future<FileNode> _create(
    String name,
    FileNodeType type,
    String? parentId, {
    String? id,
    int sizeBytes = 0,
  }) async {
    final nodes = await _load();
    if (parentId != null && !(nodes[parentId]?.isFolder ?? false)) {
      throw FileOperationException('Parent folder not found.');
    }
    final now = _clock();
    final node = FileNode(
      id: id ?? newId(),
      parentId: parentId,
      name: _validName(name),
      type: type,
      createdAt: now,
      updatedAt: now,
      sizeBytes: sizeBytes,
    );
    nodes[node.id] = node;
    await _persist();
    return node;
  }

  Future<void> _update(String id, FileNode Function(FileNode) change) async {
    final nodes = await _load();
    nodes[id] = change(_require(nodes, id));
    await _persist();
  }

  Future<FileNode> _duplicateInto(
    Map<String, FileNode> nodes,
    FileNode source,
    String? parentId,
    String name,
  ) async {
    final now = _clock();
    final copy = FileNode(
      id: newId(),
      parentId: parentId,
      name: name,
      type: source.type,
      createdAt: now,
      updatedAt: now,
      sizeBytes: source.sizeBytes,
    );
    nodes[copy.id] = copy;
    if (source.type == FileNodeType.pdf) await _blobs.copy(source.id, copy.id);
    if (!source.isFolder) await _canvases.copy(source.id, copy.id);
    final children =
        nodes.values.where((n) => n.parentId == source.id).toList();
    for (final child in children) {
      await _duplicateInto(nodes, child, copy.id, child.name);
    }
    return copy;
  }

  FileNode _require(Map<String, FileNode> nodes, String id) =>
      nodes[id] ?? (throw FileOperationException('File not found.'));

  bool _isDescendant(
    Map<String, FileNode> nodes,
    String candidate, {
    required String of,
  }) {
    String? current = nodes[candidate]?.parentId;
    while (current != null) {
      if (current == of) return true;
      current = nodes[current]?.parentId;
    }
    return false;
  }

  Iterable<String> _descendantIds(
    Map<String, FileNode> nodes,
    String id,
  ) sync* {
    for (final child in nodes.values.where((n) => n.parentId == id).toList()) {
      yield child.id;
      yield* _descendantIds(nodes, child.id);
    }
  }

  static String _validName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw FileOperationException('Name cannot be empty.');
    return trimmed;
  }
}
