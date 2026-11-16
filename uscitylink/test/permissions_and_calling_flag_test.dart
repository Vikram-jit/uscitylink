import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/services/call/call_service.dart';
import 'package:uscitylink/services/permissions/app_permissions.dart';
import 'package:uscitylink/views/call/call_log_bubble.dart';
import 'package:uscitylink/views/driver/widegts/permissions_sheet.dart';

/// A phone with scripted answers: what each permission is now, and what the OS prompt would answer.
class FakePhone implements PermissionBackend {
  FakePhone({this.android = true, Map<String, AppPermStatus>? now, Map<String, AppPermStatus>? answers}) : _now = now ?? {}, _answers = answers ?? {};
  @override
  final bool android;
  @override
  bool get isAndroid => android;
  final Map<String, AppPermStatus> _now;
  final Map<String, AppPermStatus> _answers;
  final asked = <String>[];
  var settingsOpened = 0;

  @override
  Future<AppPermStatus> status(String key) async => _now[key] ?? AppPermStatus.notAsked;
  @override
  Future<AppPermStatus> request(String key) async {
    asked.add(key);
    final r = _answers[key] ?? AppPermStatus.granted;
    _now[key] = r;
    return r;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

void main() {
  setUp(() => AppPermissions.offeredThisLaunch = false);

  group('driver call-back (only while calling is on for this driver)', () {
    final callLog = MessageModel(id: 'm1', body: 'Missed voice call', messageDirection: 'S', callId: 'c1', createdAt: '2026-11-13T10:00:00Z');

    Future<CallService> show(WidgetTester tester, {required bool enabled, required VoidCallback onCallBack}) async {
      final service = CallService(); // not Get.put: no sockets / CallKit in tests
      service.enabled.value = enabled;
      await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: DriverCallLogBubble(message: callLog, onCallBack: onCallBack, service: service))));
      return service;
    }

    testWidgets('no flag: the call log shows but there is no call-back icon and tapping does nothing', (tester) async {
      var calls = 0;
      await show(tester, enabled: false, onCallBack: () => calls++);
      expect(find.text('Missed voice call'), findsOneWidget);
      expect(find.byIcon(Icons.call_rounded), findsNothing);
      await tester.tap(find.text('Missed voice call'));
      expect(calls, 0);
    });

    testWidgets('flag on: call back is offered, and it follows the flag live', (tester) async {
      var calls = 0;
      final s = await show(tester, enabled: true, onCallBack: () => calls++);
      expect(find.byIcon(Icons.call_rounded), findsOneWidget);
      await tester.tap(find.text('Missed voice call'));
      expect(calls, 1);
      s.enabled.value = false; // staff switch it off while the chat is open
      await tester.pump();
      expect(find.byIcon(Icons.call_rounded), findsNothing);
    });
  });

  group('Allow what the app needs', () {
    testWidgets('lists every permission, call ones tagged; Android adds lock-screen calls + nearby devices', (tester) async {
      tester.view.physicalSize = const Size(900, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final phone = FakePhone();
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PermissionsSheet(permissions: AppPermissions(backend: phone)..refresh()))));
      await tester.pump();
      for (final k in ['microphone', 'notifications', 'fullscreen', 'nearby', 'camera', 'location', 'photos']) {
        expect(find.byKey(Key('permRow_$k')), findsOneWidget, reason: k);
      }
      expect(find.text('For calls'), findsNWidgets(5), reason: 'mic, notifications, lock screen, nearby devices, camera');
      // iPhone: no Android-only rows
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PermissionsSheet(permissions: AppPermissions(backend: FakePhone(android: false)..asked.clear())))));
      await tester.pump();
      expect(find.byKey(const Key('permRow_fullscreen')), findsNothing);
      expect(find.byKey(const Key('permRow_nearby')), findsNothing);
      expect(find.byKey(const Key('permRow_microphone')), findsOneWidget);
    });

    testWidgets('Allow all asks them one after another, skips allowed and blocked ones, then shows the result', (tester) async {
      tester.view.physicalSize = const Size(900, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final phone = FakePhone(
        now: {'camera': AppPermStatus.granted, 'photos': AppPermStatus.blocked},
        answers: {'location': AppPermStatus.denied},
      );
      final perms = AppPermissions(backend: phone);
      await perms.refresh();
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PermissionsSheet(permissions: perms))));
      await tester.pump();
      expect(find.byKey(const Key('permOpenSettings_photos')), findsOneWidget, reason: 'blocked: only Settings can change it');
      await tester.tap(find.byKey(const Key('permAllowAll')));
      await tester.pumpAndSettle();
      expect(phone.asked, ['microphone', 'notifications', 'fullscreen', 'nearby', 'location'], reason: 'in order; camera is allowed, photos blocked');
      expect(find.descendant(of: find.byKey(const Key('permRow_microphone')), matching: find.text('Allowed')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('permStatus_location'))).data, 'Not allowed');
      expect(tester.widget<Text>(find.byKey(const Key('permStatus_photos'))).data, 'Blocked in Settings');
      await tester.tap(find.byKey(const Key('permOpenSettings_photos')));
      expect(phone.settingsOpened, 1);
      // location was refused but can be asked again from its own button
      expect(find.byKey(const Key('permAllow_location')), findsOneWidget);
    });

    testWidgets('on the dashboard it is offered once, only while something was never asked', (tester) async {
      Future<bool> offer(AppPermissions p) async {
        late bool shown;
        await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) => Scaffold(body: ElevatedButton(key: const Key('go'), onPressed: () async => shown = await PermissionsSheet.showIfNeeded(c, permissions: p), child: const Text('go'))))));
        shown = false;
        await tester.tap(find.byKey(const Key('go')));
        await tester.pumpAndSettle();
        return shown || find.byKey(const Key('permissionsSheet')).evaluate().isNotEmpty;
      }

      tester.view.physicalSize = const Size(900, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // everything already decided (allowed / refused / blocked): nothing new to ask → no sheet
      final decided = {for (final k in ['microphone', 'notifications', 'fullscreen', 'nearby', 'camera', 'location', 'photos']) k: AppPermStatus.granted}..['camera'] = AppPermStatus.blocked..['photos'] = AppPermStatus.denied;
      expect(await offer(AppPermissions(backend: FakePhone(now: decided))), false);
      expect(AppPermissions.offeredThisLaunch, false);
      // one never asked → the sheet opens
      expect(await offer(AppPermissions(backend: FakePhone(now: {...decided, 'location': AppPermStatus.notAsked}))), true);
      expect(AppPermissions.offeredThisLaunch, true);
      await tester.tap(find.byKey(const Key('permNotNow')));
      await tester.pumpAndSettle();
      // …and not again in the same launch
      expect(await offer(AppPermissions(backend: FakePhone(now: {...decided, 'location': AppPermStatus.notAsked}))), false);
    });

    test('model: everything allowed → nothing missing; a blocked one is never re-asked', () async {
      final phone = FakePhone(now: {'photos': AppPermStatus.blocked});
      final p = AppPermissions(backend: phone);
      await p.refresh();
      expect(p.hasUnasked, true);
      expect(p.allGranted, false);
      await p.requestAll();
      expect(phone.asked.contains('photos'), false);
      await p.refresh();
      expect(p.hasUnasked, false);
      expect(p.missing.map((i) => i.key), ['photos']);
    });
  });
}
