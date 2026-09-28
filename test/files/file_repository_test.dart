import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:smart_class/core/storage/blob_store.dart';
import 'package:smart_class/core/storage/key_value_store.dart';
import 'package:smart_class/features/canvas/data/canvas_repository.dart';
import 'package:smart_class/features/canvas/domain/canvas_page.dart';
import 'package:smart_class/features/files/data/file_repository.dart';
import 'package:smart_class/features/files/domain/file_node.dart';

void main() {
  late Directory tmp;
  late KeyValueStore store;
  late CanvasRepository canvases;
  late FileRepository repo;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('smart_class_test');
    store = InMemoryKeyValueStore();
    canvases = CanvasRepository(store);
    repo = FileRepository(
      store: store,
      blobs: FileBlobStore(Directory(p.join(tmp.path, 'blobs'))),
      canvases: canvases,
    );
  });

  tearDown(() => tmp.delete(recursive: true));

  Future<File> samplePdf() async {
    final f = File(p.join(tmp.path, 'sample.pdf'));
    await f.writeAsString('%PDF-1.4 fake');
    return f;
  }

  test('supports unlimited nesting and persists the tree', () async {
    String? parent;
    for (var i = 0; i < 20; i++) {
      parent = (await repo.createFolder('level $i', parentId: parent)).id;
    }
    await repo.createBoard('deep notes', parentId: parent);

    final reloaded = FileRepository(
      store: store,
      blobs: FileBlobStore(tmp),
      canvases: canvases,
    );
    final all = await reloaded.loadAll();
    expect(all, hasLength(21));
    expect(all.singleWhere((n) => n.name == 'deep notes').parentId, parent);
  });

  test(
    'rejects empty names and moving a folder into its own subfolder',
    () async {
      final a = await repo.createFolder('A');
      final b = await repo.createFolder('B', parentId: a.id);
      expect(
        () => repo.createFolder('   '),
        throwsA(isA<FileOperationException>()),
      );
      expect(
        () => repo.move(a.id, b.id),
        throwsA(isA<FileOperationException>()),
      );
      expect(
        () => repo.move(a.id, a.id),
        throwsA(isA<FileOperationException>()),
      );
    },
  );

  test('move, rename and favorite', () async {
    final folder = await repo.createFolder('Physics');
    final board = await repo.createBoard('Lecture 1');
    await repo.move(board.id, folder.id);
    await repo.rename(board.id, 'Lecture 01');
    await repo.toggleFavorite(board.id);

    final updated = (await repo.loadAll()).singleWhere((n) => n.id == board.id);
    expect(updated.parentId, folder.id);
    expect(updated.name, 'Lecture 01');
    expect(updated.isFavorite, isTrue);

    await repo.move(board.id, null);
    expect(
      (await repo.loadAll()).singleWhere((n) => n.id == board.id).parentId,
      isNull,
    );
  });

  test(
    'duplicate copies folders deeply, including PDFs and annotations',
    () async {
      final folder = await repo.createFolder('Math');
      final pdf = await repo.importPdf(
        await samplePdf(),
        'Algebra',
        parentId: folder.id,
      );
      await canvases.save(
        pdf.id,
        const CanvasDocument().withPage(0, const CanvasPage()),
      );

      final copy = await repo.duplicate(folder.id);
      final all = await repo.loadAll();
      expect(copy.name, 'Math (copy)');
      final copiedPdf = all.singleWhere((n) => n.parentId == copy.id);
      expect(copiedPdf.type, FileNodeType.pdf);
      expect(copiedPdf.id, isNot(pdf.id));
      expect(await repo.pdfFile(copiedPdf.id).exists(), isTrue);
    },
  );

  test('delete removes folders recursively with their blobs', () async {
    final folder = await repo.createFolder('Chemistry');
    final sub = await repo.createFolder('Organic', parentId: folder.id);
    final pdf = await repo.importPdf(
      await samplePdf(),
      'Notes',
      parentId: sub.id,
    );
    expect(await repo.pdfFile(pdf.id).exists(), isTrue);

    await repo.delete(folder.id);
    expect(await repo.loadAll(), isEmpty);
    expect(await repo.pdfFile(pdf.id).exists(), isFalse);
  });
}
