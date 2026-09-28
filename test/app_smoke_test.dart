import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/app/app.dart';
import 'package:smart_class/core/storage/blob_store.dart';
import 'package:smart_class/core/storage/key_value_store.dart';
import 'package:smart_class/core/storage/user_storage.dart';
import 'package:smart_class/features/auth/application/auth_providers.dart';
import 'package:smart_class/features/auth/data/auth_repository.dart';
import 'package:smart_class/features/canvas/presentation/drawing_surface.dart';
import 'package:smart_class/features/files/application/files_providers.dart';

void main() {
  testWidgets('offline sign-in → create whiteboard → draw → back to files', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = InMemoryKeyValueStore();
    final container = ProviderContainer(
      overrides: [
        appDirectoryProvider.overrideWithValue(Directory.systemTemp),
        authRepositoryProvider.overrideWithValue(LocalAuthRepository()),
        userStorageProvider.overrideWithValue(
          UserStorage(store: store, blobs: FileBlobStore(Directory.systemTemp)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SmartClassApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Signed out → sign-in screen with offline option.
    expect(find.text('Continue offline'), findsOneWidget);
    await tester.tap(find.text('Continue offline'));
    await tester.pumpAndSettle();

    // Home: empty file manager.
    expect(find.text('This folder is empty'), findsOneWidget);

    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New whiteboard'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Lesson 1');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Whiteboard opened.
    expect(find.byType(DrawingSurface), findsOneWidget);
    final gesture = await tester.startGesture(
      const Offset(400, 400),
      kind: PointerDeviceKind.stylus,
    );
    await gesture.moveBy(const Offset(50, 30));
    await gesture.moveBy(const Offset(50, 30));
    await gesture.up();
    await tester.pump();

    // Leaving the board flushes the pending save.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Lesson 1'), findsOneWidget);

    final board = container.read(filesProvider).requireValue.single;
    final saved = await store.read('canvas/${board.id}');
    expect(saved, isNotNull);
    expect((saved!['pages'] as Map)['0']['strokes'], hasLength(1));
  });
}
