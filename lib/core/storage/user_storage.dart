import 'dart:io';

import 'package:path/path.dart' as p;

import 'blob_store.dart';
import 'key_value_store.dart';

/// All storage belonging to one account. Every user gets their own folder,
/// so data of different accounts on the same device is fully isolated.
class UserStorage {
  UserStorage({required this.store, required this.blobs});

  factory UserStorage.forUser(Directory appRoot, String userId) {
    final safeId = userId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final root = Directory(p.join(appRoot.path, 'users', safeId));
    return UserStorage(
      store: FileKeyValueStore(Directory(p.join(root.path, 'data'))),
      blobs: FileBlobStore(Directory(p.join(root.path, 'blobs'))),
    );
  }

  factory UserStorage.inMemory(Directory blobRoot) => UserStorage(
    store: InMemoryKeyValueStore(),
    blobs: FileBlobStore(blobRoot),
  );

  final KeyValueStore store;
  final BlobStore blobs;
}
