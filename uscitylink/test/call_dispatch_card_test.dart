import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:uscitylink/services/call/call_models.dart';
import 'package:uscitylink/services/call/call_service.dart';
import 'package:uscitylink/views/call/call_dispatch_card.dart';

/// Driver dashboard "Call Dispatch" card (lib/views/call/call_dispatch_card.dart).
void main() {
  Future<CallService> show(WidgetTester tester, void Function(CallService s) setup) async {
    final service = CallService(); // not Get.put: no sockets / CallKit in tests
    setup(service);
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: CallDispatchCard(channelId: 'ch1', channelName: 'U S CITYLINK INC', service: service),
        ),
      ),
    ));
    return service;
  }

  testWidgets('shows Call Dispatch with the channel when no call is on', (tester) async {
    await show(tester, (_) {});
    expect(find.text('Call Dispatch'), findsOneWidget);
    expect(find.text('U S CITYLINK INC · talk to your dispatcher'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
  });

  testWidgets('during a call it becomes "On a call · tap to return"', (tester) async {
    final s = await show(tester, (s) {
      s.phase.value = CallPhase.active;
      s.peerName.value = 'U S CITYLINK INC';
    });
    expect(find.text('On a call'), findsOneWidget);
    expect(find.text('U S CITYLINK INC · tap to return'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    s.phase.value = CallPhase.idle;
    await tester.pump();
    expect(find.text('Call Dispatch'), findsOneWidget);
  });

  testWidgets('only the Call and video buttons place a call; tapping the banner does nothing', (tester) async {
    final s = await show(tester, (_) {});
    final banner = tester.widget<InkWell>(find.byKey(const Key('callDispatchBanner')));
    expect(banner.onTap, isNull, reason: 'a stray tap on the banner must not ring dispatch');
    expect(tester.widget<InkWell>(find.byKey(const Key('callDispatchButton'))).onTap, isNotNull);
    expect(tester.widget<InkWell>(find.byKey(const Key('videoCallDispatchCard'))).onTap, isNotNull);
    await tester.tap(find.text('Call Dispatch'));
    await tester.pump();
    expect(s.phase.value, CallPhase.idle);

    // On a call the banner just goes back to it
    s.phase.value = CallPhase.active;
    await tester.pump();
    expect(tester.widget<InkWell>(find.byKey(const Key('callDispatchBanner'))).onTap, isNotNull);
  });

  testWidgets('hidden when calling is switched off', (tester) async {
    final s = await show(tester, (s) => s.enabled.value = false);
    expect(find.byKey(const Key('callDispatchCard')), findsNothing);
    s.enabled.value = true;
    await tester.pump();
    expect(find.byKey(const Key('callDispatchCard')), findsOneWidget);
  });
}
