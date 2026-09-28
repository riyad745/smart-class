import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Globally unique ids so records created offline on different devices never
/// collide when they are later synced.
String newId() => _uuid.v4();
