import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../ads/presentation/banner_ad_slot.dart';
import '../../auth/application/auth_providers.dart';
import '../application/files_providers.dart';
import '../data/file_repository.dart';
import '../domain/file_node.dart';
import 'widgets/file_tile.dart';
import 'widgets/move_dialog.dart';

/// Home screen: Explorer/Finder-style file manager.
///
/// This is the only place banner ads appear (see `AdPolicy`).
class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browser = ref.watch(fileBrowserProvider);
    final wide = Breakpoints.isWide(context);
    final sectionIndex = FileSection.values.indexOf(browser.section);
    void selectSection(int i) => ref
        .read(fileBrowserProvider.notifier)
        .openSection(FileSection.values[i]);

    const destinations = [
      (Icons.folder_outlined, Icons.folder, 'My Files'),
      (Icons.history, Icons.history, 'Recent'),
      (Icons.star_border, Icons.star, 'Favorites'),
    ];

    final content = Column(
      children: [
        const _BrowserHeader(),
        const Divider(height: 1),
        const Expanded(child: _FileList()),
        const BannerAdSlot(),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Class'),
        actions: const [_AccountMenu()],
      ),
      floatingActionButton: const _NewButton(),
      bottomNavigationBar:
          wide
              ? null
              : NavigationBar(
                selectedIndex: sectionIndex,
                onDestinationSelected: selectSection,
                destinations: [
                  for (final d in destinations)
                    NavigationDestination(
                      icon: Icon(d.$1),
                      selectedIcon: Icon(d.$2),
                      label: d.$3,
                    ),
                ],
              ),
      body:
          wide
              ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: sectionIndex,
                    onDestinationSelected: selectSection,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final d in destinations)
                        NavigationRailDestination(
                          icon: Icon(d.$1),
                          selectedIcon: Icon(d.$2),
                          label: Text(d.$3),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              )
              : content,
    );
  }
}

class _BrowserHeader extends ConsumerStatefulWidget {
  const _BrowserHeader();

  @override
  ConsumerState<_BrowserHeader> createState() => _BrowserHeaderState();
}

class _BrowserHeaderState extends ConsumerState<_BrowserHeader> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final browser = ref.watch(fileBrowserProvider);
    final notifier = ref.read(fileBrowserProvider.notifier);
    final all = ref.watch(filesProvider).asData?.value ?? const <FileNode>[];
    if (browser.query.isEmpty && _search.text.isNotEmpty) _search.clear();

    final crumbs =
        browser.section == FileSection.myFiles
            ? folderPath(all, browser.folderId)
            : const <FileNode>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: AppSpacing.sm,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (crumbs.isNotEmpty)
                IconButton(
                  tooltip: 'Up',
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: () => notifier.openFolder(crumbs.last.parentId),
                ),
              TextButton(
                onPressed:
                    () =>
                        browser.section == FileSection.myFiles
                            ? notifier.openFolder(null)
                            : null,
                child: Text(browser.section.label),
              ),
              for (final folder in crumbs) ...[
                const Icon(Icons.chevron_right, size: 18),
                TextButton(
                  onPressed: () => notifier.openFolder(folder.id),
                  child: Text(folder.name),
                ),
              ],
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search all files',
                    suffixIcon:
                        browser.query.isEmpty
                            ? null
                            : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => notifier.search(''),
                            ),
                  ),
                  onChanged: notifier.search,
                ),
              ),
              PopupMenuButton<FileSort>(
                tooltip: 'Sort',
                icon: const Icon(Icons.sort),
                initialValue: browser.sort,
                onSelected: notifier.sortBy,
                itemBuilder:
                    (_) => [
                      for (final s in FileSort.values)
                        CheckedPopupMenuItem(
                          value: s,
                          checked: s == browser.sort,
                          child: Text(s.label),
                        ),
                    ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FileList extends ConsumerWidget {
  const _FileList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browser = ref.watch(fileBrowserProvider);
    final visible = ref.watch(visibleFilesProvider);
    final all = ref.watch(filesProvider).asData?.value ?? const <FileNode>[];
    final byId = {for (final n in all) n.id: n};

    return visible.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load files: $e')),
      data: (nodes) {
        if (nodes.isEmpty) {
          return switch ((browser.query.isNotEmpty, browser.section)) {
            (true, _) => const EmptyState(
              icon: Icons.search_off,
              title: 'No matching files',
            ),
            (_, FileSection.recent) => const EmptyState(
              icon: Icons.history,
              title: 'Files you open appear here',
            ),
            (_, FileSection.favorites) => const EmptyState(
              icon: Icons.star_border,
              title: 'No favorites yet',
              message: 'Use a file\'s menu → "Add to favorites".',
            ),
            _ => const EmptyState(
              icon: Icons.note_add_outlined,
              title: 'This folder is empty',
              message: 'Tap "New" to import a PDF or create a whiteboard.',
            ),
          };
        }
        final showLocation =
            browser.query.isNotEmpty || browser.section != FileSection.myFiles;
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: nodes.length,
          itemBuilder: (context, i) {
            final node = nodes[i];
            return FileTile(
              key: ValueKey(node.id),
              node: node,
              subtitle:
                  showLocation
                      ? (byId[node.parentId]?.name ?? 'My Files')
                      : null,
              onAction: (action) => _handle(context, ref, node, action, all),
            );
          },
        );
      },
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    FileNode node,
    FileAction action,
    List<FileNode> all,
  ) async {
    final files = ref.read(filesProvider.notifier);
    try {
      switch (action) {
        case FileAction.open:
          await openFileNode(context, ref, node);
        case FileAction.rename:
          final name = await showTextInputDialog(
            context,
            title: 'Rename',
            initialValue: node.name,
            confirmLabel: 'Rename',
          );
          if (name != null) await files.rename(node.id, name);
        case FileAction.move:
          final target = await showMoveDialog(context, all: all, moving: node);
          if (target != null) await files.move(node.id, target.folderId);
        case FileAction.duplicate:
          await files.duplicate(node.id);
        case FileAction.favorite:
          await files.toggleFavorite(node.id);
        case FileAction.delete:
          final ok = await showConfirmDialog(
            context,
            title: 'Delete "${node.name}"?',
            message:
                node.isFolder
                    ? 'The folder and everything inside it will be deleted.'
                    : 'This file and its annotations will be deleted.',
            confirmLabel: 'Delete',
            destructive: true,
          );
          if (ok) await files.delete(node.id);
      }
    } on FileOperationException catch (e) {
      if (context.mounted) showMessage(context, e.message);
    }
  }
}

/// Opens a folder in the browser, or a file in its teaching screen.
Future<void> openFileNode(
  BuildContext context,
  WidgetRef ref,
  FileNode node,
) async {
  if (node.isFolder) {
    ref.read(fileBrowserProvider.notifier).openFolder(node.id);
    return;
  }
  await ref.read(filesProvider.notifier).markOpened(node.id);
  if (!context.mounted) return;
  switch (node.type) {
    case FileNodeType.pdf:
      context.push(AppRoutes.pdf(node.id));
    case FileNodeType.board:
      context.push(AppRoutes.board(node.id));
    case FileNodeType.folder:
      break;
  }
}

class _NewButton extends ConsumerWidget {
  const _NewButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, -8),
      builder:
          (context, controller, _) => FloatingActionButton.extended(
            onPressed:
                () =>
                    controller.isOpen ? controller.close() : controller.open(),
            icon: const Icon(Icons.add),
            label: const Text('New'),
          ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.picture_as_pdf_outlined),
          onPressed: () => _importPdf(context, ref),
          child: const Text('Import PDF'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.draw_outlined),
          onPressed: () => _newBoard(context, ref),
          child: const Text('New whiteboard'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.create_new_folder_outlined),
          onPressed: () => _newFolder(context, ref),
          child: const Text('New folder'),
        ),
      ],
    );
  }

  /// New items go into the open folder, or the root outside "My Files".
  String? _targetFolder(WidgetRef ref) {
    final browser = ref.read(fileBrowserProvider);
    return browser.section == FileSection.myFiles ? browser.folderId : null;
  }

  Future<void> _newFolder(BuildContext context, WidgetRef ref) async {
    final name = await showTextInputDialog(
      context,
      title: 'New folder',
      initialValue: 'New folder',
      confirmLabel: 'Create',
    );
    if (name == null) return;
    await ref
        .read(filesProvider.notifier)
        .createFolder(name, parentId: _targetFolder(ref));
  }

  Future<void> _newBoard(BuildContext context, WidgetRef ref) async {
    final name = await showTextInputDialog(
      context,
      title: 'New whiteboard',
      initialValue:
          'Class notes ${MaterialLocalizations.of(context).formatShortDate(DateTime.now())}',
      confirmLabel: 'Create',
    );
    if (name == null) return;
    final node = await ref
        .read(filesProvider.notifier)
        .createBoard(name, parentId: _targetFolder(ref));
    if (context.mounted) await openFileNode(context, ref, node);
  }

  Future<void> _importPdf(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    final files = ref.read(filesProvider.notifier);
    for (final f in picked) {
      final path = f.path;
      if (path == null) continue;
      final name =
          f.name.toLowerCase().endsWith('.pdf')
              ? f.name.substring(0, f.name.length - 4)
              : f.name;
      await files.importPdf(File(path), name, parentId: _targetFolder(ref));
    }
    if (context.mounted && picked.isNotEmpty) {
      showMessage(
        context,
        'Imported ${picked.length} PDF${picked.length == 1 ? '' : 's'}',
      );
    }
  }
}

class _AccountMenu extends ConsumerWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return MenuAnchor(
      builder:
          (context, controller, _) => IconButton(
            tooltip: user?.label ?? 'Account',
            icon: CircleAvatar(
              radius: 16,
              child: Text((user?.label ?? '?').characters.first.toUpperCase()),
            ),
            onPressed:
                () =>
                    controller.isOpen ? controller.close() : controller.open(),
          ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push(AppRoutes.settings),
          child: const Text('Settings'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.logout),
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
          child: Text(
            user?.isGuest ?? false ? 'Leave offline mode' : 'Sign out',
          ),
        ),
      ],
    );
  }
}
