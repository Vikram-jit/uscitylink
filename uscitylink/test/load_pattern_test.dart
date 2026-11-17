import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/staff/load_models.dart';
import 'package:uscitylink/services/staff/typed_load_handler.dart';
import 'package:uscitylink/services/trip/trip_models.dart';
import 'package:uscitylink/utils/load_format.dart';
import 'package:uscitylink/utils/load_text.dart';
import 'package:uscitylink/views/staff/view/loads/loads_common.dart';
import 'package:uscitylink/views/staff/widgets/template_dialog.dart';

/// The one load pattern (lib/utils/load_format.dart, server tripMessages.formatLoad): only the LOAD # is
/// required, the pickup and the drop are each optional, a place or a date not confirmed is PENDING.
void main() {
  // These tests cover loads made from chat text (off in the app: loads come from the form) — on here
  setUpAll(() => loadsFromChat = true);

  Map<String, dynamic> stop(int id, String type, {String? city, String? state, String? name, String? appt}) =>
      {'id': id, 'seq': id, 'type': type, 'city': city, 'state': state, 'name': name, 'appointment_local': appt};
  Map<String, dynamic> leg(List<Map<String, dynamic>> stops, {bool loaded = false}) => {
        'id': 1, 'load_id': 7, 'leg_no': 1, 'trip_no': '0056000', 'status': 'scheduled', 'driver_profile_id': 'p1', 'truck_number': '35865', 'loaded_trailer': loaded, 'stops': stops,
      };
  Map<String, dynamic> load(List<Map<String, dynamic>> legs) =>
      {'id': 7, 'load_no': '0056000', 'invoice_no': '0056000', 'type': 'direct', 'status': 'scheduled', 'created_at': '2026-11-12T10:00:00Z', 'legs': legs};

  test('the template: not a load until it has a LOAD #; with one it is (pickup and drop both pending)', () {
    expect(kLoadTemplate.split('\n').first, 'LOAD #');
    expect(kLoadTemplate, contains('PICKUP\nPENDING'));
    expect(kLoadTemplate, contains('DROP\nPENDING'));
    expect(looksLikeLoad(kLoadTemplate), false);
    final filled = kLoadTemplate.replaceFirst('LOAD #', 'LOAD # 5501');
    expect(looksLikeLoad(filled), true, reason: 'a LOAD # and PICKUP / DROP headings');
    expect(loadNoIn(filled), '5501');
    expect(loadMissingNo(filled), false);
    expect(loadMissingNo(kLoadTemplate), false, reason: 'the blank template is not blocked as a load without its number');
  });

  test('routeText: each side can be unknown — Pending, never the same address twice', () {
    LoadLeg l(List<Map<String, dynamic>> s, {bool loaded = false}) => LoadLeg.fromJson(leg(s, loaded: loaded));
    expect(l([stop(1, 'pickup', city: 'Fresno', state: 'CA'), stop(2, 'drop', city: 'Atlanta', state: 'GA')]).routeText, 'Fresno, CA → Atlanta, GA');
    expect(l([stop(1, 'drop', city: 'Atlanta', state: 'GA')]).routeText, 'Pending → Atlanta, GA', reason: 'one address, no pickup');
    expect(l([stop(1, 'pickup', city: 'Fresno', state: 'CA')]).routeText, 'Fresno, CA → Pending');
    expect(l([]).routeText, 'Pending → Pending');
    expect(l([stop(1, 'drop', city: 'Atlanta', state: 'GA')], loaded: true).routeText, 'Loaded trailer → Atlanta, GA');
    expect(l([stop(1, 'pickup'), stop(2, 'drop', city: 'Atlanta', state: 'GA')]).routeText, 'Pending → Atlanta, GA', reason: 'a pickup with no address yet');
    final s = LoadStop.fromJson(stop(1, 'pickup'));
    expect(s.pending, true);
    expect(s.title, 'Pending');
  });

  test('NewStop: an empty pickup or drop is pending and left out; any address counts', () {
    expect(NewStop(type: 'pickup').hasPlace, false);
    expect(NewStop(type: 'pickup').worthKeeping, false);
    expect(NewStop(type: 'drop', city: 'Atlanta').hasPlace, true);
    expect(NewStop(type: 'drop', name: 'FreshPoint').hasPlace, true, reason: 'a name alone is enough while the rest is pending');
    final dateOnly = NewStop(type: 'drop')..appointment = '2026-11-16T06:00';
    expect(dateOnly.hasPlace, false);
    expect(dateOnly.worthKeeping, true, reason: 'a date with the place still pending is kept');
  });

  testWidgets('the load card says PENDING for the side with no stop (and does not repeat the address)', (tester) async {
    Future<void> show(Map<String, dynamic> json) => tester.pumpWidget(GetMaterialApp(home: Scaffold(body: SingleChildScrollView(child: LoadCard(load: StaffLoad.fromJson(json), names: const {'p1': 'Raj Singh'})))));

    await show(load([leg([stop(1, 'drop', city: 'Atlanta', state: 'GA', name: 'FreshPoint')])]));
    expect(find.byKey(const Key('pending_pickup')), findsOneWidget);
    expect(find.byKey(const Key('pending_delivery')), findsNothing);
    expect(find.text('Atlanta, GA'), findsOneWidget, reason: 'the address once, on the drop side only');

    await show(load([leg([])]));
    expect(find.byKey(const Key('pending_pickup')), findsOneWidget);
    expect(find.byKey(const Key('pending_delivery')), findsOneWidget);

    await show(load([leg([stop(1, 'pickup', city: 'Fresno', state: 'CA'), stop(2, 'drop', city: 'Atlanta', state: 'GA')])]));
    expect(find.byKey(const Key('pending_pickup')), findsNothing);
    expect(find.byKey(const Key('pending_delivery')), findsNothing);
    expect(find.text('Fresno, CA'), findsOneWidget);
    expect(find.text('Atlanta, GA'), findsOneWidget);
  });

  testWidgets('"Load format" is the first template to pick and puts the blank pattern in the message box', (tester) async {
    var picked = '';
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: loadFormatTile(() => picked = kLoadTemplate))));
    expect(find.text('Load format'), findsOneWidget);
    expect(find.textContaining('LOAD # (required)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('loadFormatTemplate')));
    expect(picked, kLoadTemplate);
  });

  testWidgets('a Load # with no pickup / drop address is saved as a plan: the sender is told nothing was sent', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
    TypedLoadHandler.handle({'kind': 'planned', 'loadNo': '0056000', 'driverName': 'Terry'});
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Load saved as a plan'), findsOneWidget);
    expect(find.textContaining('nothing was sent'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 2));
  });

  group('driver app', () {
    Map<String, dynamic> trip(List<Map<String, dynamic>> stops, {bool loaded = false}) => {
          'id': 5, 'trip_no': '0056000', 'status': 'planned', 'truck_number': '35865', 'loaded_trailer': loaded, 'sent_at': '2026-11-12T10:00:00Z', 'stops': stops,
        };

    test('the route says Pending for the side dispatch has not confirmed', () {
      expect(CurrentTrip.fromTrip(trip([stop(1, 'drop', city: 'Atlanta', state: 'GA')])).routeText, 'Pending → Atlanta, GA');
      expect(CurrentTrip.fromTrip(trip([stop(1, 'pickup', city: 'Fresno', state: 'CA')])).routeText, 'Fresno, CA → Pending');
      expect(CurrentTrip.fromTrip(trip([])).routeText, 'Pending → Pending');
      expect(CurrentTrip.fromTrip(trip([stop(1, 'drop', city: 'Atlanta', state: 'GA')], loaded: true)).routeText, 'Loaded trailer → Atlanta, GA');
      expect(CurrentTrip.fromTrip(trip([stop(1, 'pickup'), stop(2, 'drop', city: 'Atlanta', state: 'GA')])).stops.first.title, 'Pending');
    });
  });
}
