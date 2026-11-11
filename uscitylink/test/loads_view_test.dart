import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:uscitylink/services/trip/trip_models.dart';
import 'package:uscitylink/services/trip/trip_service.dart';
import 'package:uscitylink/views/trip/loads_view.dart';

/// Driver bottom-nav Loads screen (lib/views/trip/loads_view.dart).
void main() {
  Map<String, dynamic> trip(int id, String status, {String? completed}) => {
        'id': id,
        'trip_no': 'L00$id',
        'status': status,
        'truck_number': '24565',
        'temperature': 'REFER BILLS',
        'sent_at': '2026-11-06T10:36:23.000Z',
        'completed_at': completed,
        'stops': [
          {'id': id * 10 + 1, 'seq': 1, 'type': 'pickup', 'name': 'COLD LINK', 'street': '609 DACETOWN RD', 'city': 'ELLISVILLE', 'state': 'MS', 'zip': '39437'},
          {'id': id * 10 + 2, 'seq': 2, 'type': 'drop', 'name': 'COSTCO', 'city': 'MIRA LOMA', 'state': 'CA', 'appointment_local': '2026-11-06T03:15'},
        ],
      };

  Future<TripService> show(WidgetTester tester, {Map<String, dynamic>? current, List<Map<String, dynamic>> past = const []}) async {
    final service = TripService(); // not Get.put: no sockets / REST in tests
    if (current != null) {
      service.current.value = CurrentTrip.fromResponse({'trip': current, 'next': {'action': 'rolling', 'label': 'Loaded — rolling'}});
    }
    service.history.assignAll([if (current != null) CurrentTrip.fromTrip(current), ...past.map(CurrentTrip.fromTrip)]);
    await tester.pumpWidget(GetMaterialApp(home: LoadsView(service: service)));
    return service;
  }

  testWidgets('no load: says dispatch will send it', (tester) async {
    await show(tester);
    expect(find.textContaining('No load right now'), findsOneWidget);
    expect(find.textContaining('delivered loads will be listed here'), findsOneWidget);
  });

  testWidgets('current load on top with its button; history below without it', (tester) async {
    await show(tester, current: trip(7, 'accepted'), past: [trip(5, 'completed', completed: '2026-11-03T18:00:00.000Z')]);
    expect(find.byKey(const Key('currentTripCard')), findsOneWidget);
    expect(find.text('Loaded — rolling'), findsOneWidget);
    // History lists the older load only (the current one is the card above)
    expect(find.byKey(const Key('load_5')), findsOneWidget);
    expect(find.byKey(const Key('load_7')), findsNothing);
    expect(find.text('ELLISVILLE, MS → MIRA LOMA, CA'), findsOneWidget);
    expect(find.text('2 stops · Truck 24565 · Nov 3'), findsOneWidget);
  });

  testWidgets('tapping a past load opens its stops and times', (tester) async {
    await show(tester, past: [trip(5, 'completed', completed: '2026-11-03T18:00:00.000Z')]);
    await tester.tap(find.byKey(const Key('load_5')));
    await tester.pumpAndSettle();
    expect(find.text('Trip #L005'), findsOneWidget);
    expect(find.text('Pickup · COLD LINK'), findsOneWidget);
    expect(find.text('609 DACETOWN RD, ELLISVILLE MS 39437'), findsOneWidget);
    expect(find.text('Drop · COSTCO'), findsOneWidget);
    expect(find.text('11/06 03:15 AM'), findsOneWidget);
  });

  testWidgets('dashboard shortcut: shown only when there is no current load', (tester) async {
    final service = TripService();
    await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: MyLoadsShortcut(service: service))));
    expect(find.byKey(const Key('myLoadsShortcut')), findsOneWidget);
    service.current.value = CurrentTrip.fromResponse({'trip': trip(7, 'accepted'), 'next': null});
    await tester.pump();
    expect(find.byKey(const Key('myLoadsShortcut')), findsNothing);
  });

  testWidgets('opened from the chat it has a back arrow; as a tab it does not', (tester) async {
    await tester.pumpWidget(GetMaterialApp(home: LoadsView(service: TripService(), standalone: true)));
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    await tester.pumpWidget(GetMaterialApp(home: LoadsView(service: TripService())));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
  });

  testWidgets('Up next: lined-up loads are listed read-only, in order, with what they wait for', (tester) async {
    final service = TripService();
    service.upcoming.assignAll([
      CurrentTrip.fromTrip({...trip(73, 'scheduled'), 'trip_no': 'L0073-2', 'position': 1, 'waits_for': 'Leg 1 (L0073) handing over'}),
      CurrentTrip.fromTrip({...trip(80, 'offered'), 'position': 2}),
    ]);
    await tester.pumpWidget(GetMaterialApp(home: LoadsView(service: service)));
    expect(find.text('Up next'), findsWidgets);
    expect(find.byKey(const Key('upNextNote')), findsOneWidget);
    expect(find.byKey(const Key('upNextPos_73')), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('Starts after: Leg 1 (L0073) handing over'), findsOneWidget);
    expect(find.text('Waiting for dispatch'), findsOneWidget);
    // Opening it shows the stops, no trip buttons
    await tester.tap(find.byKey(const Key('load_73')));
    await tester.pumpAndSettle();
    expect(find.text('Trip #L0073-2'), findsOneWidget);
    expect(find.text('Drop · COSTCO'), findsOneWidget);
    expect(find.byKey(const Key('upNextNote')), findsOneWidget);
    expect(find.byKey(const Key('tripNextButton')), findsNothing);
  });
}
