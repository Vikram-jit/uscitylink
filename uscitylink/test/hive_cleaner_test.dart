import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:uscitylink/hive_boxes.dart';
import 'package:uscitylink/utils/closed_box_guard.dart';
import 'package:uscitylink/utils/hive_cleaner.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_cleaner_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('logout deletes every box the app uses, open or closed', () async {
    // Open boxes the way the app does: some typed, some dynamic, some left closed on disk
    for (final name in HiveBoxes.all) {
      final box = name.hashCode.isEven
          ? await Hive.openBox<int>(name)
          : await Hive.openBox(name);
      await box.put('k', 1);
    }
    final closed = await Hive.openBox('closed_but_on_disk');
    await closed.put('k', 1);
    await closed.close();

    final failed = await clearAllHiveData();

    expect(failed, isEmpty);
    for (final name in HiveBoxes.all) {
      expect(await Hive.boxExists(name), isFalse, reason: '$name survived logout');
      expect(Hive.isBoxOpen(name), isFalse, reason: '$name still open');
    }
  });

  test('a box missing from the list is still wiped if it is open', () async {
    final forgotten = await Hive.openBox('feature_added_later_box');
    await forgotten.put('messages', 'previous user');

    await clearAllHiveData();

    expect(await Hive.boxExists('feature_added_later_box'), isFalse);
  });

  test('the chat message cache is cleared (it was missing before)', () async {
    final chat = await Hive.openBox(HiveBoxes.channelMessagesCache);
    await chat.put('channel-1_1', ['staff-only message']);

    await clearAllHiveData();

    expect(await Hive.boxExists(HiveBoxes.channelMessagesCache), isFalse);
  });

  test('a request finishing after logout is skipped, not a crash', () async {
    // Like DashboardController: the box is fetched first, the response (and cache write) comes later
    final box = await Hive.openBox<int>(HiveBoxes.driverDashboard);

    await clearAllHiveData(); // logout while the request is still running

    expect(box.isOpen, isFalse); // controllers check this before caching
    Object? thrown;
    try {
      await box.put('dashboardBox', 1); // an unguarded late write
    } catch (e) {
      thrown = e;
    }
    // ...and anything unguarded still throws exactly the error the app-wide handler ignores
    expect(thrown, isNotNull);
    expect(isClosedBoxError(thrown!), isTrue);
    expect(isClosedBoxError(StateError('something else')), isFalse);
  });

  test('no code opens a box by a hand-typed name (it would not be cleared)', () {
    final literal = RegExp(r'''openBox(?:<[^>]*(?:<[^>]*>)?[^>]*>)?\(\s*['"]([^'"]+)['"]''');
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.endsWith('hive_cleaner.dart')) continue;
      for (final m in literal.allMatches(file.readAsStringSync())) {
        offenders.add('${file.path}: ${m.group(1)}');
      }
    }
    expect(offenders, isEmpty,
        reason: 'Use a HiveBoxes constant (and add it to HiveBoxes.all): $offenders');
  });
}
