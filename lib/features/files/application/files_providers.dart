import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../canvas/application/canvas_providers.dart';
import '../data/file_repository.dart';
import '../domain/file_node.dart';

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  final storage = ref.watch(userStorageProvider);
  return FileRepository(
    store: storage.store,
    blobs: storage.blobs,
    canvases: ref.watch(canvasRepositoryProvider),
  );
});

/// The full file tree of the signed-in user. All mutations go through this
/// controller so every screen watching [filesProvider] refreshes.
class FilesController extends AsyncNotifier<List<FileNode>> {
  FileRepository get _repo => ref.read(fileRepositoryProvider);

  @override
  Future<List<FileNode>> build() => ref.watch(fileRepositoryProvider).loadAll();

  Future<FileNode> createFolder(String name, {String? parentId}) =>
      _run((r) => r.createFolder(name, parentId: parentId));

  Future<FileNode> createBoard(String name, {String? parentId}) =>
      _run((r) => r.createBoard(name, parentId: parentId));

  Future<FileNode> importPdf(File file, String name, {String? parentId}) =>
      _run((r) => r.importPdf(file, name, parentId: parentId));

  Future<void> rename(String id, String name) =>
      _run((r) => r.rename(id, name));
  Future<void> move(String id, String? parentId) =>
      _run((r) => r.move(id, parentId));
  Future<FileNode> duplicate(String id) => _run((r) => r.duplicate(id));
  Future<void> delete(String id) => _run((r) => r.delete(id));
  Future<void> toggleFavorite(String id) => _run((r) => r.toggleFavorite(id));
  Future<void> markOpened(String id) => _run((r) => r.markOpened(id));

  Future<T> _run<T>(Future<T> Function(FileRepository repo) operation) async {
    final result = await operation(_repo);
    state = AsyncData(await _repo.loadAll());
    return result;
  }
}

final filesProvider = AsyncNotifierProvider<FilesController, List<FileNode>>(
  FilesController.new,
);

final fileByIdProvider = Provider.family<FileNode?, String>((ref, id) {
  final files = ref.watch(filesProvider).asData?.value ?? const [];
  for (final f in files) {
    if (f.id == id) return f;
  }
  return null;
});

// --- browsing state ---------------------------------------------------------

enum FileSection {
  myFiles('My Files'),
  recent('Recent'),
  favorites('Favorites');

  const FileSection(this.label);
  final String label;
}

class FileBrowserState {
  const FileBrowserState({
    this.section = FileSection.myFiles,
    this.folderId,
    this.query = '',
    this.sort = FileSort.name,
  });

  final FileSection section;
  final String? folderId;
  final String query;
  final FileSort sort;

  FileBrowserState copyWith({
    FileSection? section,
    Object? folderId = _keep,
    String? query,
    FileSort? sort,
  }) => FileBrowserState(
    section: section ?? this.section,
    folderId: identical(folderId, _keep) ? this.folderId : folderId as String?,
    query: query ?? this.query,
    sort: sort ?? this.sort,
  );
}

const Object _keep = Object();

class FileBrowserController extends Notifier<FileBrowserState> {
  @override
  FileBrowserState build() => const FileBrowserState();

  void openSection(FileSection section) =>
      state = FileBrowserState(section: section, sort: state.sort);
  void openFolder(String? folderId) =>
      state = state.copyWith(
        section: FileSection.myFiles,
        folderId: folderId,
        query: '',
      );
  void search(String query) => state = state.copyWith(query: query);
  void sortBy(FileSort sort) => state = state.copyWith(sort: sort);
}

final fileBrowserProvider =
    NotifierProvider<FileBrowserController, FileBrowserState>(
      FileBrowserController.new,
    );

/// What the file list should show for the current section/folder/search.
final visibleFilesProvider = Provider<AsyncValue<List<FileNode>>>((ref) {
  final browser = ref.watch(fileBrowserProvider);
  return ref.watch(filesProvider).whenData((all) => filterFiles(all, browser));
});

/// Pure filtering logic, unit-tested in test/files/file_filter_test.dart.
List<FileNode> filterFiles(List<FileNode> all, FileBrowserState browser) {
  final query = browser.query.trim().toLowerCase();
  if (query.isNotEmpty) {
    // Search looks through the whole tree, like Explorer/Finder.
    return sortNodes(
      all.where((n) => n.name.toLowerCase().contains(query)),
      browser.sort,
    );
  }
  switch (browser.section) {
    case FileSection.recent:
      final opened =
          all.where((n) => !n.isFolder && n.lastOpenedAt != null).toList()
            ..sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));
      return opened.take(30).toList();
    case FileSection.favorites:
      return sortNodes(all.where((n) => n.isFavorite), browser.sort);
    case FileSection.myFiles:
      return sortNodes(
        all.where((n) => n.parentId == browser.folderId),
        browser.sort,
      );
  }
}

/// Folder chain from the root to [folderId], for breadcrumbs.
List<FileNode> folderPath(List<FileNode> all, String? folderId) {
  final byId = {for (final n in all) n.id: n};
  final path = <FileNode>[];
  var current = folderId == null ? null : byId[folderId];
  while (current != null) {
    path.insert(0, current);
    current = current.parentId == null ? null : byId[current.parentId];
  }
  return path;
}
