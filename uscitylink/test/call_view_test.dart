import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/services/call/call_models.dart';
import 'package:uscitylink/services/call/call_service.dart';
import 'package:uscitylink/views/call/call_log_bubble.dart';
import 'package:uscitylink/views/call/call_view.dart';

/// Call screen states (lib/views/call/call_view.dart) and the call-log bubble.
void main() {
  Future<CallService> show(WidgetTester tester, void Function(CallService s) setup) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final service = CallService(); // not Get.put: no sockets / CallKit in tests
    service.peerName.value = 'Sukhdev Singh';
    service.peerSubtitle.value = 'Driver · U S CITYLINK INC';
    setup(service);
    await tester.pumpWidget(GetMaterialApp(home: CallView(service: service)));
    await tester.pump(const Duration(milliseconds: 50));
    return service;
  }

  String status(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('callStatus'))).data ?? '';

  testWidgets('outgoing: "Calling…", mute disabled until answered, hang up shown', (tester) async {
    await show(tester, (s) => s.phase.value = CallPhase.outgoing);
    expect(find.text('Sukhdev Singh'), findsOneWidget);
    expect(find.text('Driver · U S CITYLINK INC'), findsOneWidget);
    expect(status(tester), 'Calling…');
    expect(find.text('Cancel'), findsOneWidget);
    final mute = tester.widget<Opacity>(find.ancestor(of: find.text('Mute'), matching: find.byType(Opacity)).first);
    expect(mute.opacity, lessThan(1));
  });

  testWidgets('dispatch line: all busy → "You\'re #2 in line" with the waiting banner', (tester) async {
    final s = await show(tester, (s) {
      s.phase.value = CallPhase.queued;
      s.queuePosition.value = 2;
    });
    expect(status(tester), "You're #2 in line");
    expect(find.byKey(const Key('queueBanner')), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    s.queuePosition.value = 1;
    await tester.pump();
    expect(status(tester), "You're #1 in line");
    s.phase.value = CallPhase.outgoing;
    await tester.pump();
    expect(status(tester), 'Calling…');
    expect(find.byKey(const Key('queueBanner')), findsNothing);
  });

  testWidgets('incoming while the app is open: Accept and Decline, no call controls yet', (tester) async {
    await show(tester, (s) {
      s.peerName.value = 'U S CITYLINK INC';
      s.peerSubtitle.value = 'Dispatch · Super Admin';
      s.phase.value = CallPhase.incoming;
    });
    expect(status(tester), 'Incoming call…');
    expect(find.byKey(const Key('acceptButton')), findsOneWidget);
    expect(find.byKey(const Key('declineButton')), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.byKey(const Key('muteButton')), findsNothing);
    expect(find.byKey(const Key('hangupButton')), findsNothing);
  });

  testWidgets('on call: live timer, mute and speaker toggle', (tester) async {
    final s = await show(tester, (s) {
      s.phase.value = CallPhase.active;
      s.answeredAt.value = DateTime.now().subtract(const Duration(seconds: 65));
    });
    expect(status(tester), '1:05');
    await tester.tap(find.byKey(const Key('muteButton')));
    await tester.pump();
    expect(s.muted.value, isTrue);
    expect(find.text('Unmute'), findsOneWidget);
    await tester.tap(find.byKey(const Key('speakerButton')));
    await tester.pump();
    expect(s.speaker.value, isTrue);
  });

  testWidgets('network drop shows Reconnecting…; other side muted is shown', (tester) async {
    await show(tester, (s) {
      s.phase.value = CallPhase.active;
      s.answeredAt.value = DateTime.now();
      s.reconnecting.value = true;
      s.remoteMuted.value = true;
    });
    expect(status(tester), 'Reconnecting…');
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.text('They muted their microphone'), findsOneWidget);
  });

  testWidgets('ended: shows the outcome, no call controls', (tester) async {
    await show(tester, (s) {
      s.phase.value = CallPhase.ended;
      s.endedText.value = 'Call ended · 3:42';
    });
    expect(status(tester), 'Call ended · 3:42');
    expect(find.byKey(const Key('hangupButton')), findsNothing);
    expect(find.byKey(const Key('muteButton')), findsNothing);
  });

  testWidgets('call-log bubble wording for driver and staff', (tester) async {
    Widget bubble(String body, String dir, bool driver) => MaterialApp(
          home: Scaffold(body: CallLogBubble(message: MessageModel(body: body, messageDirection: dir), viewerIsDriver: driver)),
        );
    await tester.pumpWidget(bubble('Missed voice call', 'S', true));
    expect(find.textContaining('Dispatch called'), findsOneWidget);
    expect(find.byIcon(Icons.phone_missed_rounded), findsOneWidget);

    await tester.pumpWidget(bubble('Voice call · 3:42', 'R', true));
    expect(find.textContaining('You called dispatch'), findsOneWidget);
    expect(find.byIcon(Icons.call_made_rounded), findsOneWidget);

    await tester.pumpWidget(bubble('Voice call · 0:12', 'R', false));
    expect(find.textContaining('Driver called'), findsOneWidget);
    expect(find.byIcon(Icons.call_received_rounded), findsOneWidget);
  });

  test('duration format', () {
    expect(formatCallDuration(0), '0:00');
    expect(formatCallDuration(222), '3:42');
    expect(formatCallDuration(3725), '1:02:05');
  });
}
