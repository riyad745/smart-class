/// Kind of entry in the file tree.
enum FileNodeType {
  folder,

  /// An imported PDF. Its annotations are stored separately, keyed by id.
  pdf,

  /// A whiteboard / class-notes document made of canvas pages.
  board,
}

/// A node in the user's "My Files" tree.
///
/// The tree is stored flat: every node points to its parent via [parentId]
/// (`null` = root). This keeps unlimited nesting cheap, makes "move" a
/// single-field update and maps 1:1 onto a cloud table row for sync.
class FileNode {
  const FileNode({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.isFavorite = false,
    this.lastOpenedAt,
    this.sizeBytes = 0,
  });

  final String id;
  final String? parentId;
  final String name;
  final FileNodeType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final DateTime? lastOpenedAt;
  final int sizeBytes;

  bool get isFolder => type == FileNodeType.folder;

  FileNode copyWith({
    String? name,
    Object? parentId = _unset,
    bool? isFavorite,
    DateTime? updatedAt,
    DateTime? lastOpenedAt,
    int? sizeBytes,
  }) => FileNode(
    id: id,
    parentId: identical(parentId, _unset) ? this.parentId : parentId as String?,
    name: name ?? this.name,
    type: type,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isFavorite: isFavorite ?? this.isFavorite,
    lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    sizeBytes: sizeBytes ?? this.sizeBytes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'parentId': parentId,
    'name': name,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isFavorite': isFavorite,
    'lastOpenedAt': lastOpenedAt?.toIso8601String(),
    'sizeBytes': sizeBytes,
  };

  factory FileNode.fromJson(Map<String, dynamic> json) => FileNode(
    id: json['id'] as String,
    parentId: json['parentId'] as String?,
    name: json['name'] as String,
    type: FileNodeType.values.byName(json['type'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    isFavorite: json['isFavorite'] as bool? ?? false,
    lastOpenedAt:
        json['lastOpenedAt'] == null
            ? null
            : DateTime.parse(json['lastOpenedAt'] as String),
    sizeBytes: json['sizeBytes'] as int? ?? 0,
  );
}

const Object _unset = Object();

enum FileSort {
  name('Name'),
  modified('Date modified'),
  type('Type');

  const FileSort(this.label);
  final String label;
}

/// Sorts folders first, then by [sort].
List<FileNode> sortNodes(Iterable<FileNode> nodes, FileSort sort) {
  final list = nodes.toList();
  list.sort((a, b) {
    if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
    return switch (sort) {
      FileSort.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      FileSort.modified => b.updatedAt.compareTo(a.updatedAt),
      FileSort.type =>
        a.type.index != b.type.index
            ? a.type.index.compareTo(b.type.index)
            : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    };
  });
  return list;
}
