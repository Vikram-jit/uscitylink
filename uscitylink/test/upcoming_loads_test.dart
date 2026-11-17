import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:uscitylink/services/trip/trip_models.dart';
import 'package:uscitylink/services/trip/trip_service.dart';
import 'package:uscitylink/views/trip/current_trip_card.dart';
import 'package:uscitylink/views/trip/upcoming_loads.dart';

/// The driver's Accept / Reject: on the load just sent (main card) and on every Upcoming load.
class FakeTrips extends TripService {
  final calls = <String>[];
  @override
  Future<bool> respond(CurrentTrip trip, String response, {String? note}) async {
    calls.add('${trip.id} $response${note == null ? '' : ' [$note]'}');
    return true;
  }
}

void main() {
  Map<String, dynamic> trip(int id, String status, {String? response, String? appt, String? loadNo}) => {
        'id': id, 'trip_no': loadNo ?? '00$id', 'invoice_no': loadNo ?? '00$id', 'status': status, 'driver_response': response, 'truck_number': '35865', 'trailer_numbers': '107065', 'temperature': '34 CONT.',
        'stops': [
          {'id': id * 10 + 1, 'seq': 1, 'type': 'pickup', 'name': 'ECHO COLD', 'city': 'FRESNO', 'state': 'CA', 'appointment_local': appt},
          {'id': id * 10 + 2, 'seq': 2, 'type': 'drop', 'name': 'FRESHPOINT', 'city': 'FAIRBURN', 'state': 'GA'},
        ],
      };

  Future<FakeTrips> show(WidgetTester tester, {List<Map<String, dynamic>> upcoming = const [], Map<String, dynamic>? main, Map<String, dynamic>? next}) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final s = FakeTrips();
    final data = {'trip': main, 'next': next, 'upcoming': upcoming};
    s.current.value = CurrentTrip.fromResponse(data);
    s.upcoming.assignAll(CurrentTrip.upcomingFrom(data));
    await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [CurrentTripCard(service: s, onOpenChat: () {}), UpcomingLoads(service: s)])))));
    return s;
  }

  test('the answer carries the upcoming loads in order, and what the driver already answered', () {
    final up = CurrentTrip.upcomingFrom({'upcoming': [trip(3, 'scheduled'), trip(4, 'scheduled', response: 'accepted')]});
    expect(up.map((t) => t.id), [3, 4]);
    expect(up[0].accepted, false);
    expect(up[1].accepted, true);
    expect(CurrentTrip.upcomingFrom({'trip': null}), isEmpty, reason: 'an older server sends no list');
    expect(CurrentTrip.upcomingFrom(null), isEmpty);
    expect(CurrentTrip.fromResponse({'trip': null, 'next': null, 'upcoming': [trip(3, 'scheduled')]}), isNull, reason: 'no current load, only upcoming');
  });

  testWidgets('nothing lined up: no Upcoming section', (tester) async {
    await show(tester);
    expect(find.byKey(const Key('upcomingLoads')), findsNothing);
  });

  testWidgets('Upcoming lists every lined-up load in order with its route and appointment; Accept and Reject on each', (tester) async {
    final s = await show(tester, upcoming: [trip(3, 'scheduled', appt: '2026-11-16T06:00', loadNo: '0056003'), trip(4, 'scheduled', loadNo: '0056004')]);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Load 0056003'), findsOneWidget);
    expect(find.text('Load 0056004'), findsOneWidget);
    expect(find.text('FRESNO, CA → FAIRBURN, GA'), findsNWidgets(2));
    expect(find.text('Pickup 11/16 06:00 AM'), findsOneWidget);
    expect(find.text('Truck 35865 · Trailer 107065 · Temp 34 CONT.'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('upcomingAccept_3')));
    await tester.pump();
    expect(s.calls, ['3 accept']);
  });

  testWidgets('Reject is one tap: no sheet, no questions — the load goes straight back to dispatch', (tester) async {
    final s = await show(tester, upcoming: [trip(3, 'scheduled')]);
    await tester.tap(find.byKey(const Key('upcomingReject_3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rejectReasonSheet')), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(s.calls, ['3 reject']);
  });

  testWidgets('an accepted upcoming load says so and can still be rejected; it has no second Accept', (tester) async {
    final s = await show(tester, upcoming: [trip(3, 'scheduled', response: 'accepted')]);
    expect(find.byKey(const Key('upcomingAccepted_3')), findsOneWidget);
    expect(find.byKey(const Key('upcomingAccept_3')), findsNothing);
    expect(find.textContaining('becomes your load when the current one is delivered'), findsOneWidget);
    await tester.tap(find.byKey(const Key('upcomingReject_3')));
    await tester.pumpAndSettle();
    expect(s.calls, ['3 reject']);
  });

  testWidgets('the load just sent shows Accept and Reject on the main card; Accept sends accept', (tester) async {
    final s = await show(tester, main: trip(7, 'planned'), next: {'action': 'accept', 'label': 'Accept'});
    expect(find.byKey(const Key('tripNextButton')), findsOneWidget);
    expect(find.byKey(const Key('tripRejectButton')), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tripNextButton')));
    await tester.pump();
    expect(s.calls, ['7 accept']);
  });

  testWidgets('Reject on the main card is one tap too: no sheet, the load is sent back', (tester) async {
    final s = await show(tester, main: trip(7, 'planned'), next: {'action': 'accept', 'label': 'Accept'});
    await tester.tap(find.byKey(const Key('tripRejectButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rejectReasonSheet')), findsNothing);
    expect(s.calls, ['7 reject']);
  });

  testWidgets('after Accept the main card is one big "Loaded — rolling" button (no Reject); then Delivered — end trip', (tester) async {
    await show(tester, main: trip(7, 'accepted'), next: {'action': 'rolling', 'label': 'Loaded — rolling'});
    expect(find.text('Loaded — rolling'), findsOneWidget);
    expect(find.byKey(const Key('tripRejectButton')), findsNothing);
    await show(tester, main: trip(7, 'rolling'), next: {'action': 'end', 'label': 'Delivered — end trip', 'stopId': 72});
    expect(find.text('Delivered — end trip'), findsOneWidget);
    expect(find.byKey(const Key('tripRejectButton')), findsNothing);
  });

  testWidgets('on a phone-width screen "Reject" and "Accept" stay on one line (no "Reje / ct")', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400); // 360 dp wide
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final s = FakeTrips();
    s.upcoming.assignAll([CurrentTrip.fromTrip(trip(3, 'scheduled'))]);
    await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: UpcomingLoads(service: s)))));
    for (final word in ['Reject', 'Accept']) {
      final size = tester.getSize(find.text(word));
      expect(size.height, lessThan(24), reason: '$word on one line');
    }
    expect(tester.getSize(find.byKey(const Key('upcomingReject_3'))).width, greaterThan(110), reason: 'room for icon + word');
  });

  // ---------- Settings → Loads switches (web admin) ----------

  test('the switches read from the server; missing ones keep their defaults', () {
    final f = LoadFeatures.fromJson({'driver_loads': true, 'driver_buttons': false, 'driver_upcoming': true, 'loads_from_chat': true});
    expect(f.driverButtons, false);
    expect(f.canTap, false);
    expect(f.loadsFromChat, true);
    expect(LoadFeatures.fromJson(null), LoadFeatures.defaults);
    expect(LoadFeatures.defaults.canTap, true);
    expect(LoadFeatures.defaults.loadsFromChat, false, reason: 'loads from chat: off unless an admin turns it on');
  });

  testWidgets('buttons off: the load and the Upcoming list are shown, but no Accept / Reject / Rolling / Undo', (tester) async {
    final s = await show(tester, main: trip(1, 'planned'), next: {'action': 'accept', 'label': 'Accept'}, upcoming: [trip(3, 'scheduled')]);
    expect(find.byKey(const Key('tripNextButton')), findsOneWidget);
    s.features.value = const LoadFeatures(driverButtons: false);
    await tester.pump();
    expect(find.byKey(const Key('currentTripCard')), findsOneWidget, reason: 'the load is still shown');
    expect(find.byKey(const Key('upcomingLoads')), findsOneWidget);
    expect(find.byKey(const Key('tripNextButton')), findsNothing);
    expect(find.byKey(const Key('tripRejectButton')), findsNothing);
    expect(find.byKey(const Key('upcomingAccept_3')), findsNothing);
    expect(find.byKey(const Key('upcomingReject_3')), findsNothing);
    // back on → the buttons are back
    s.features.value = LoadFeatures.defaults;
    await tester.pump();
    expect(find.byKey(const Key('tripNextButton')), findsOneWidget);
    expect(find.byKey(const Key('upcomingAccept_3')), findsOneWidget);
  });

  testWidgets('upcoming off: no Upcoming list; loads off: no card and no list at all', (tester) async {
    final s = await show(tester, main: trip(1, 'planned'), next: {'action': 'accept', 'label': 'Accept'}, upcoming: [trip(3, 'scheduled')]);
    s.features.value = const LoadFeatures(driverUpcoming: false);
    await tester.pump();
    expect(find.byKey(const Key('upcomingLoads')), findsNothing);
    expect(find.byKey(const Key('currentTripCard')), findsOneWidget);
    s.features.value = const LoadFeatures(driverLoads: false);
    await tester.pump();
    expect(find.byKey(const Key('currentTripCard')), findsNothing);
    expect(find.byKey(const Key('upcomingLoads')), findsNothing);
  });
}
