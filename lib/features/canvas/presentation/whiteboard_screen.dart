import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../classroom/application/classroom_tools_provider.dart';
import '../../classroom/presentation/teaching_scaffold.dart';
import '../../files/application/files_providers.dart';
import 'canvas_document_scope.dart';
import 'whiteboard_panel.dart';

/// Full-screen whiteboard for a board (class notes) file.
class WhiteboardScreen extends ConsumerWidget {
  const WhiteboardScreen({super.key, required this.fileId});

  final String fileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(fileByIdProvider(fileId));
    final showToolbar = ref.watch(
      classroomToolsProvider.select((s) => s.toolbarVisible),
    );
    return TeachingScaffold(
      title: file?.name ?? 'Whiteboard',
      body: CanvasDocumentScope(
        documentId: fileId,
        builder:
            (context, controller) => WhiteboardPanel(
              controller: controller,
              showToolbar: showToolbar,
            ),
      ),
    );
  }
}
