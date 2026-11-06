import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uscitylink/views/staff/view/calls/staff_call_log_view.dart';

/// Staff → Call log (lib/views/staff/view/calls/staff_call_log_view.dart) against a fake GET /calls.
void main() {
  final calls = [
    {
      'id': 'c1', 'type': 'audio', 'status': 'cancelled', 'direction': 'driver_to_dispatch',
      'driver_id': 'd1', 'driver_name': 'AMAN KUMAR', 'driver_phone': '+1 555 123 4567',
      'initiator_name': 'AMAN KUMAR', 'answered_by_name': null, 'rang_count': 12,
      'started_at': DateTime.now().toUtc().toIso8601String(), 'duration_sec': 0, 'end_reason': 'caller_cancelled',
    },
    {
      'id': 'c2', 'type': 'video', 'status': 'completed', 'direction': 'dispatch_to_driver',
      'driver_id': 'd2', 'driver_name': 'Gurvinder Singh', 'driver_phone': null,
      'initiator_name': 'test', 'answered_by_name': 'Gurvinder Singh', 'rang_count': 1,
      'started_at': DateTime.now().toUtc().toIso8601String(), 'duration_sec': 75, 'wait_sec': 4,
      'recording': {'status': 'ready'},
    },
  ];
  final asked = <Map<String, String>>[];

  MockClient server() => MockClient((req) async {
        expect(req.headers['Authorization'], 'Bearer test-token');
        if (req.url.path.endsWith('/calls/c2/recording')) {
          return http.Response(
              jsonEncode({
                'status': true,
                'data': {'url': 'https://example.com/c2.m4a', 'video_url': null, 'sha256': 'ab' * 32}
              }),
              200);
        }
        if (req.url.path.endsWith('/calls/c2')) {
          return http.Response(
              jsonEncode({
                'status': true,
                'data': {
                  'recording': {'status': 'ready', 'sha256': 'ab' * 32, 'has_video': false, 'duration_sec': 75},
                  'participants': [
                    {'name': 'test', 'role': 'caller', 'outcome': 'caller'},
                    {'name': 'Gurvinder Singh', 'role': 'callee', 'outcome': 'answered'},
                  ]
                }
              }),
              200);
        }
        if (req.url.path.endsWith('/calls/c1')) {
          return http.Response(
              jsonEncode({
                'status': true,
                'data': {
                  'participants': [
                    {'name': 'AMAN KUMAR', 'role': 'caller', 'outcome': 'caller'},
                    {'name': 'Navjot', 'role': 'callee', 'outcome': 'missed'},
                    {'name': 'test', 'role': 'callee', 'outcome': 'missed'},
                  ]
                }
              }),
              200);
        }
        expect(req.url.path, endsWith('/calls'));
        asked.add(req.url.queryParameters);
        final status = req.url.queryParameters['status'];
        final list = status == null ? calls : calls.where((c) => status.split(',').contains(c['status'])).toList();
        return http.Response(jsonEncode({'status': true, 'data': {'calls': list, 'total': list.length, 'page': 1}}), 200);
      });

  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'test-token'});
    Get.reset();
    asked.clear();
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 60)));
    await tester.pumpAndSettle();
  }

  testWidgets('lists calls with direction, phone and status; filters; details show who it rang', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final client = server();
    await http.runWithClient(() async {
      await tester.pumpWidget(const GetMaterialApp(home: StaffCallLogView()));
      await settle(tester);

      expect(find.text('AMAN KUMAR (+1 555 123 4567)'), findsOneWidget);
      expect(find.text('driver → dispatch'), findsOneWidget);
      expect(find.text('Missed'), findsWidgets);
      expect(find.text('Gurvinder Singh'), findsOneWidget, reason: 'no phone on file: name only');
      expect(find.textContaining('test → driver · 1:15'), findsOneWidget);
      expect(find.byKey(const Key('callLogCall-c1')), findsOneWidget);

      await tester.tap(find.text('Answered').first);
      await settle(tester);
      expect(asked.last['status'], 'completed');
      expect(find.text('AMAN KUMAR (+1 555 123 4567)'), findsNothing);

      await tester.tap(find.text('All').first);
      await settle(tester);
      await tester.tap(find.byKey(const Key('callLogRow-c1')));
      await settle(tester);
      expect(find.text('Missed (caller hung up)'), findsOneWidget);
      expect(find.text('Caller hung up before it was answered'), findsOneWidget);
      expect(find.text('Rang 2 people'), findsOneWidget);
      expect(find.text("Didn't answer"), findsNWidgets(2));
      expect(find.byKey(const Key('callLogDetailCall')), findsOneWidget);
      expect(find.byKey(const Key('playRecording')), findsNothing, reason: 'a missed call has no recording');
      Navigator.of(tester.element(find.text('Rang 2 people'))).pop();
      await settle(tester);

      // Answered + recorded: play button and fingerprint, then the links (download)
      await tester.tap(find.byKey(const Key('callLogRow-c2')));
      await settle(tester);
      expect(find.text('Play recording'), findsOneWidget);
      expect(find.textContaining('abababababababab…'), findsOneWidget);
      expect(find.text('Answered'), findsWidgets);

      await tester.ensureVisible(find.byKey(const Key('playRecording')));
      await tester.tap(find.byKey(const Key('playRecording')));
      await settle(tester);
      expect(find.byKey(const Key('downloadAudio')), findsOneWidget);
      expect(find.byKey(const Key('downloadVideo')), findsNothing);
      expect(find.byKey(const Key('playRecording')), findsNothing);
    }, () => client);
  });
}
