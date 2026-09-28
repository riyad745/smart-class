import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/file_node.dart';

/// Actions available from a file's context menu.
enum FileAction { open, rename, move, duplicate, favorite, delete }

class FileTypeIcon extends StatelessWidget {
  const FileTypeIcon({super.key, required this.type, this.size = 32});

  final FileNodeType type;
  final double size;

  @override
  Widget build(BuildContext context) => switch (type) {
    FileNodeType.folder => Icon(
      Icons.folder,
      color: AppColors.folder,
      size: size,
    ),
    FileNodeType.pdf => Icon(
      Icons.picture_as_pdf,
      color: AppColors.pdf,
      size: size,
    ),
    FileNodeType.board => Icon(Icons.draw, color: AppColors.board, size: size),
  };
}

class FileTile extends StatelessWidget {
  const FileTile({
    super.key,
    required this.node,
    required this.onAction,
    this.subtitle,
  });

  final FileNode node;
  final ValueChanged<FileAction> onAction;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final modified = localizations.formatMediumDate(node.updatedAt);
    return ListTile(
      leading: FileTypeIcon(type: node.type),
      title: Text(node.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (subtitle != null) subtitle!,
          modified,
          if (node.type == FileNodeType.pdf && node.sizeBytes > 0)
            _formatSize(node.sizeBytes),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => onAction(FileAction.open),
      onLongPress: () => _showSheet(context),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (node.isFavorite)
            const Icon(Icons.star, color: Colors.amber, size: 20),
          PopupMenuButton<FileAction>(
            tooltip: 'More',
            onSelected: onAction,
            itemBuilder:
                (_) => [
                  for (final a in FileAction.values)
                    PopupMenuItem(
                      value: a,
                      child: _ActionRow(action: a, node: node),
                    ),
                ],
          ),
        ],
      ),
    );
  }

  void _showSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder:
        (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final a in FileAction.values)
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onAction(a);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    child: _ActionRow(action: a, node: node),
                  ),
                ),
            ],
          ),
        ),
  );

  static String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action, required this.node});

  final FileAction action;
  final FileNode node;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (action) {
      FileAction.open => (Icons.open_in_new, 'Open'),
      FileAction.rename => (Icons.drive_file_rename_outline, 'Rename'),
      FileAction.move => (Icons.drive_file_move_outline, 'Move'),
      FileAction.duplicate => (Icons.copy, 'Duplicate'),
      FileAction.favorite =>
        node.isFavorite
            ? (Icons.star_border, 'Remove from favorites')
            : (Icons.star, 'Add to favorites'),
      FileAction.delete => (Icons.delete_outline, 'Delete'),
    };
    final color =
        action == FileAction.delete
            ? Theme.of(context).colorScheme.error
            : null;
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 16),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
