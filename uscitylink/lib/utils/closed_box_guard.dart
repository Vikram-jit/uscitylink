import 'package:hive_ce/hive.dart';

/// True for the error Hive throws when something writes to (or reads from) a box that has been
/// closed. Logout deletes every box, so a request that finishes afterwards hits this; it only
/// means "the user logged out, skip the cache write".
bool isClosedBoxError(Object error) =>
    error is HiveError && error.message.contains('already been closed');
