import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uscitylink/controller/staff/notification_settings_controller.dart';
import 'package:uscitylink/services/staff/notification_settings_service.dart';
import 'package:uscitylink/views/staff/view/settings/staff_settings_view.dart';

extension NotificationMuteForTest on NotificationMute {
  static NotificationMute expired() =>
      NotificationMute(muted: true, until: DateTime.now().subtract(const Duration(minutes: 1)));
}

/// A fake /user/notification-mute that behaves like the server.
MockClient fakeServer(List<Map<String, dynamic>> calls) {
  final until = <String, DateTime?>{'messages': null, 'calls': null};
  final forever = <String, bool>{'messages': false, 'calls': false};
  Map<String, dynamic> one(String k) =>
      {'muted': until[k] != null, 'mutedUntil': until[k]?.toUtc().toIso8601String(), 'forever': forever[k]};
  Map<String, dynamic> state() => {
        'status': true,
        'data': {...one('messages'), 'calls': one('calls')},
      };
  return MockClient((req) async {
    expect(req.url.path, endsWith('/user/notification-mute'));
    expect(req.headers['Authorization'], 'Bearer test-token');
    if (req.method == 'PUT') {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      calls.add(body);
      final k = body['kind'] == 'calls' ? 'calls' : 'messages';
      forever[k] = body['forever'] == true;
      until[k] = forever[k]! ? DateTime.utc(2099, 12, 31) : (body['minutes'] == null ? null : DateTime.now().add(Duration(minutes: body['minutes'])));
    }
    return http.Response(jsonEncode(state()), 200);
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'test-token'});
    Get.reset();
  });

  test('mute for a while, forever, and back on', () async {
    final calls = <Map<String, dynamic>>[];
    final server = fakeServer(calls);
    await http.runWithClient(() async {
      final c = NotificationSettingsController();
      await c.load();
      expect(c.isMuted, isFalse);

      await c.muteFor(minutes: 60);
      expect(calls.last, {'minutes': 60, 'forever': false});
      expect(c.isMuted, isTrue);
      expect(c.mute.value.until!.difference(DateTime.now()).inMinutes, inInclusiveRange(58, 60));

      await c.muteFor(forever: true);
      expect(calls.last, {'minutes': null, 'forever': true});
      expect(c.mute.value.forever, isTrue);

      await c.unmute();
      expect(calls.last, {'minutes': null, 'forever': false});
      expect(c.isMuted, isFalse);
    }, () => server);
  });

  test('call alerts mute separately from messages', () async {
    final calls = <Map<String, dynamic>>[];
    final server = fakeServer(calls);
    await http.runWithClient(() async {
      final c = NotificationSettingsController();
      await c.load();
      await c.muteFor(minutes: 60);
      expect(c.isMuted, isTrue);
      expect(c.isCallMuted, isFalse, reason: 'muting messages must not stop calls');

      await c.muteFor(kind: MuteKind.calls, forever: true);
      expect(calls.last, {'minutes': null, 'forever': true, 'kind': 'calls'});
      expect(c.isCallMuted, isTrue);
      expect(c.isMuted, isTrue);

      await c.unmute();
      expect(c.isMuted, isFalse);
      expect(c.isCallMuted, isTrue, reason: 'turning messages on leaves calls muted');

      await c.unmute(kind: MuteKind.calls);
      expect(calls.last, {'minutes': null, 'forever': false, 'kind': 'calls'});
      expect(c.isCallMuted, isFalse);
    }, () => server);
  });

  test('older server without call mute: calls stay on', () async {
    await http.runWithClient(() async {
      final c = NotificationSettingsController();
      await c.load();
      expect(c.isCallMuted, isFalse);
    }, () => MockClient((_) async => http.Response(jsonEncode({'status': true, 'data': {'muted': true, 'forever': true}}), 200)));
  });

  test('a timed mute that has run out counts as on', () {
    final c = NotificationSettingsController();
    c.mute.value = NotificationMuteForTest.expired();
    expect(c.isMuted, isFalse);
  });

  testWidgets('settings screen: switch on → pick a duration → muted', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final calls = <Map<String, dynamic>>[];
    final server = fakeServer(calls);
    await http.runWithClient(() async {
      await tester.pumpWidget(const GetMaterialApp(home: StaffSettingsView()));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.text('On'), findsNWidgets(2));
      expect(find.text('Driver and group messages alert this phone'), findsOneWidget);

      await tester.tap(find.byKey(const Key('muteSwitch')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('For 8 hours'));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(calls.last, {'minutes': 480, 'forever': false});
      expect(find.text('Muted'), findsOneWidget);
      expect(find.textContaining('Muted until'), findsOneWidget);

      await tester.tap(find.text('Turn on now'));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(calls.last, {'minutes': null, 'forever': false});
      expect(find.text('On'), findsNWidgets(2));
    }, () => server);
  });

  testWidgets('settings screen: mute call alerts on its own card', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final calls = <Map<String, dynamic>>[];
    final server = fakeServer(calls);
    await http.runWithClient(() async {
      await tester.pumpWidget(const GetMaterialApp(home: StaffSettingsView()));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.text('Call alerts'), findsOneWidget);
      expect(find.text('Incoming calls ring this phone'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('callMuteSwitch')));
      await tester.tap(find.byKey(const Key('callMuteSwitch')));
      await tester.pumpAndSettle();
      expect(find.text('Mute call alerts'), findsNWidgets(2)); // card row + sheet title
      await tester.tap(find.text('For 1 hour'));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(calls.last, {'minutes': 60, 'forever': false, 'kind': 'calls'});
      expect(find.text('Muted'), findsOneWidget);
      expect(find.text('Driver and group messages alert this phone'), findsOneWidget, reason: 'messages still on');

      await tester.ensureVisible(find.byKey(const Key('callUnmute')));
      await tester.tap(find.byKey(const Key('callUnmute')));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(calls.last, {'minutes': null, 'forever': false, 'kind': 'calls'});
      expect(find.text('Muted'), findsNothing);
    }, () => server);
  });
}
