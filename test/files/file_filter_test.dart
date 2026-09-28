import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/features/files/application/files_providers.dart';
import 'package:smart_class/features/files/domain/file_node.dart';

FileNode node(
  String id,
  FileNodeType type, {
  String? parent,
  bool favorite = false,
  DateTime? opened,
  int day = 1,
}) => FileNode(
  id: id,
  name: id,
  type: type,
  parentId: parent,
  isFavorite: favorite,
  lastOpenedAt: opened,
  createdAt: DateTime(2026, 1, day),
  updatedAt: DateTime(2026, 1, day),
);

void main() {
  final all = [
    node('zeta.pdf', FileNodeType.pdf, day: 3),
    node('Alpha', FileNodeType.folder),
    node(
      'beta board',
      FileNodeType.board,
      favorite: true,
      opened: DateTime(2026, 2, 1),
    ),
    node(
      'inside.pdf',
      FileNodeType.pdf,
      parent: 'Alpha',
      opened: DateTime(2026, 3, 1),
    ),
  ];

  test('My Files lists the current folder, folders first then by name', () {
    final result = filterFiles(all, const FileBrowserState());
    expect(result.map((n) => n.id), ['Alpha', 'beta board', 'zeta.pdf']);
  });

  test('sort by date modified keeps folders first', () {
    final result = filterFiles(
      all,
      const FileBrowserState(sort: FileSort.modified),
    );
    expect(result.map((n) => n.id), ['Alpha', 'zeta.pdf', 'beta board']);
  });

  test('search looks through every folder', () {
    final result = filterFiles(all, const FileBrowserState(query: 'PDF'));
    expect(result.map((n) => n.id), ['inside.pdf', 'zeta.pdf']);
  });

  test('recent is ordered by last opened', () {
    final result = filterFiles(
      all,
      const FileBrowserState(section: FileSection.recent),
    );
    expect(result.map((n) => n.id), ['inside.pdf', 'beta board']);
  });

  test('favorites', () {
    final result = filterFiles(
      all,
      const FileBrowserState(section: FileSection.favorites),
    );
    expect(result.map((n) => n.id), ['beta board']);
  });

  test('folderPath builds breadcrumbs', () {
    final nested = [
      ...all,
      node('Deeper', FileNodeType.folder, parent: 'Alpha'),
    ];
    expect(folderPath(nested, 'Deeper').map((n) => n.id), ['Alpha', 'Deeper']);
    expect(folderPath(nested, null), isEmpty);
  });
}
