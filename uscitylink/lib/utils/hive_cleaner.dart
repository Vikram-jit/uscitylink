import 'package:hive_ce/hive.dart';
import 'package:uscitylink/hive_boxes.dart';

/// Deletes everything the app cached in Hive: every box in [HiveBoxes.all], then any other box
/// that is still open (so a box someone forgot to list is still wiped for the logged-out user).
/// Returns the names of boxes that could not be deleted (empty = all gone).
///
/// Do NOT look a box up with `Hive.box(name)` to clear it first: that call throws when the box was
/// opened with a type (`Box<MessageModel>`, `Box<int>`, ...), which is how almost every box here is
/// opened. `deleteBoxFromDisk` closes and deletes an open box of any type.
Future<List<String>> clearAllHiveData({void Function(String message)? log}) async {
  final failed = <String>[];

  for (final name in HiveBoxes.all) {
    try {
      await Hive.deleteBoxFromDisk(name);
      log?.call('✅ Deleted box: $name');
    } catch (e) {
      failed.add(name);
      log?.call('❌ Failed to delete box $name: $e');
    }
  }

  // Anything still open belongs to a feature added after the list was written
  try {
    await Hive.deleteFromDisk();
  } catch (e) {
    log?.call('⚠️ Error deleting remaining open boxes: $e');
  }
  return failed;
}
