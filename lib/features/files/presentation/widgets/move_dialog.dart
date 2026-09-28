import 'package:flutter/material.dart';

import '../../domain/file_node.dart';

/// Result of [showMoveDialog]: the chosen destination (null = root).
class MoveTarget {
  const MoveTarget(this.folderId);
  final String? folderId;
}

/// Lets the user pick a destination folder. Folders that are [moving] or
/// inside it are hidden, so a folder can't be moved into itself.
Future<MoveTarget?> showMoveDialog(
  BuildContext context, {
  required List<FileNode> all,
  required FileNode moving,
}) {
  final excluded = <String>{moving.id};
  bool isExcluded(FileNode n) {
    String? current = n.id;
    final byId = {for (final f in all) f.id: f};
    while (current != null) {
      if (excluded.contains(current)) return true;
      current = byId[current]?.parentId;
    }
    return false;
  }

  final folders = all.where((n) => n.isFolder && !isExcluded(n)).toList();

  List<Widget> buildLevel(String? parentId, int depth) => [
    for (final f in sortNodes(
      folders.where((f) => f.parentId == parentId),
      FileSort.name,
    )) ...[
      ListTile(
        contentPadding: EdgeInsets.only(left: 16.0 + depth * 20, right: 16),
        leading: const Icon(Icons.folder_outlined),
        title: Text(f.name),
        enabled: f.id != moving.parentId,
        onTap: () => Navigator.pop(context, MoveTarget(f.id)),
      ),
      ...buildLevel(f.id, depth + 1),
    ],
  ];

  return showDialog<MoveTarget>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text('Move "${moving.name}"'),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('My Files'),
                  enabled: moving.parentId != null,
                  onTap: () => Navigator.pop(context, const MoveTarget(null)),
                ),
                ...buildLevel(null, 1),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
  );
}
