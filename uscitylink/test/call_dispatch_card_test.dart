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

  testWidgets('hidden when calling is switched off', (tester) async {
    final s = await show(tester, (s) => s.enabled.value = false);
    expect(find.byKey(const Key('callDispatchCard')), findsNothing);
    s.enabled.value = true;
    await tester.pump();
    expect(find.byKey(const Key('callDispatchCard')), findsOneWidget);
  });
}
