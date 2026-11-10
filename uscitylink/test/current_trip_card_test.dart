import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:uscitylink/services/trip/trip_models.dart';
import 'package:uscitylink/services/trip/trip_service.dart';
import 'package:uscitylink/views/trip/current_trip_card.dart';

/// Driver dashboard trip card (lib/views/trip/current_trip_card.dart).
void main() {
  // The server's GET trips/current answer for a sent 2-stop load
  Map<String, dynamic> response({String status = 'rolling', Map<String, dynamic>? next, bool firstDone = true}) => {
        'trip': {
          'id': 7,
          'trip_no': '008870',
          'status': status,
          'truck_number': '23865',
          'trailer_numbers': '10265',
          'temperature': '34 CONT.',
          'loaded_trailer': false,
          'problems': [],
          'stops': [
            {
              'id': 2,
              'seq': 2,
              'type': 'drop',
              'name': 'SYSCO - FREMONT',
              'city': 'FREMONT',
              'state': 'CA',
              'appointment_local': '2026-10-23T09:00',
            },
            {
              'id': 1,
              'seq': 1,
              'type': 'pickup',
              'name': 'DECATUR COLD STORAGE',
              'city': 'DECATUR',
              'state': 'AL',
              'appointment_local': '2026-10-19T13:30',
              'arrived_at': firstDone ? '2026-10-19T18:20:00.000Z' : null,
              'departed_at': firstDone ? '2026-10-19T19:05:00.000Z' : null,
            },
          ],
        },
        'next': next ?? {'action': 'arrive', 'label': 'Arrived at SYSCO - FREMONT', 'stopId': 2},
      };

  Future<TripService> show(WidgetTester tester, Map<String, dynamic>? data, {bool compact = false}) async {
    final service = TripService(); // not Get.put: no sockets / REST in tests
    service.current.value = data == null ? null : CurrentTrip.fromResponse(data);
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: compact ? CurrentTripCard(service: service, compact: true) : CurrentTripCard(service: service, onOpenChat: () {}),
        ),
      ),
    ));
    return service;
  }

  testWidgets('hidden when the driver has no trip', (tester) async {
    await show(tester, null);
    expect(find.byKey(const Key('currentTripCard')), findsNothing);
  });

  testWidgets('shows the load, stops in order and the next step', (tester) async {
    await show(tester, response());
    expect(find.text('Trip #008870'), findsOneWidget);
    expect(find.text('Rolling'), findsOneWidget);
    expect(find.text('Truck 23865 · Trailer 10265 · Temp 34 CONT.'), findsOneWidget);
    final pickup = tester.getTopLeft(find.text('Pickup · DECATUR COLD STORAGE'));
    final drop = tester.getTopLeft(find.text('Drop · SYSCO - FREMONT'));
    expect(pickup.dy < drop.dy, isTrue);
    expect(find.text('FREMONT, CA · Appt 10/23 09:00 AM'), findsOneWidget);
    expect(find.text('DECATUR, AL · Appt 10/19 01:30 PM'), findsOneWidget);
    expect(find.text('Arrived at SYSCO - FREMONT'), findsOneWidget);
  });

  testWidgets('delivered: asks for the paperwork instead of a next step', (tester) async {
    await show(tester, response(status: 'ended', next: {'action': 'none', 'label': ''}));
    expect(find.byKey(const Key('tripPaperworkButton')), findsOneWidget);
    expect(find.text('Send BOL / POD photos'), findsOneWidget);
    expect(find.byKey(const Key('tripNextButton')), findsNothing);
  });

  testWidgets('on hold: no button, dispatch will update them', (tester) async {
    await show(tester, response(status: 'on_hold'));
    expect(find.text('On hold — dispatch will update you here'), findsOneWidget);
    expect(find.byKey(const Key('tripNextButton')), findsNothing);
  });

  testWidgets('ending asks once before telling dispatch', (tester) async {
    await show(tester, response(next: {'action': 'end', 'label': 'Delivered — end trip', 'stopId': 2}));
    await tester.tap(find.byKey(const Key('tripNextButton')));
    await tester.pumpAndSettle();
    expect(find.text('Dispatch is told the load is delivered. Then send the BOL / POD photos in the chat.'), findsOneWidget);
    await tester.tap(find.text('Not yet'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('an assistant suggestion shows Yes / No', (tester) async {
    final s = await show(tester, response());
    s.suggestion.value = TripSuggestion(tripId: 7, action: 'arrive', label: 'Arrived at SYSCO - FREMONT', stopId: 2);
    await tester.pump();
    expect(find.text('Update the trip: Arrived at SYSCO - FREMONT?'), findsOneWidget);
    await tester.tap(find.text('No'));
    await tester.pump();
    expect(s.suggestion.value, isNull);
  });

  testWidgets('in the chat: one line and the button; the header opens the stops', (tester) async {
    await show(tester, response(), compact: true);
    expect(find.text('Trip #008870'), findsOneWidget);
    expect(find.text('Drop · SYSCO - FREMONT · Appt 10/23 09:00 AM'), findsOneWidget);
    expect(find.text('Arrived at SYSCO - FREMONT'), findsOneWidget);
    expect(find.text('Pickup · DECATUR COLD STORAGE'), findsNothing);
    expect(find.text('Report problem'), findsNothing);
    await tester.tap(find.byKey(const Key('tripCardHeader')));
    await tester.pump();
    expect(find.text('Pickup · DECATUR COLD STORAGE'), findsOneWidget);
    expect(find.text('Report problem'), findsOneWidget);
  });

  testWidgets('in the chat after delivery: send the paperwork right here', (tester) async {
    await show(tester, response(status: 'ended', next: {'action': 'none', 'label': ''}), compact: true);
    expect(find.byKey(const Key('tripPaperworkHint')), findsOneWidget);
    expect(find.byKey(const Key('tripPaperworkButton')), findsNothing);
  });

  testWidgets('dashboard: "All loads" in the header opens the Loads screen', (tester) async {
    var opened = 0;
    final service = TripService();
    service.current.value = CurrentTrip.fromResponse(response());
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: CurrentTripCard(service: service, onOpenLoads: () => opened++))),
    ));
    await tester.tap(find.byKey(const Key('tripAllLoads')));
    expect(opened, 1);
  });
}
