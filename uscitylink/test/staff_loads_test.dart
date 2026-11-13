import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/staff/load_models.dart';
import 'package:uscitylink/services/staff/loads_service.dart';
import 'package:uscitylink/services/staff/staff_api_client.dart';
import 'package:uscitylink/utils/load_text.dart';
import 'package:uscitylink/views/staff/view/loads/staff_add_load_view.dart';
import 'package:uscitylink/views/staff/view/loads/staff_load_detail_view.dart';
import 'package:uscitylink/views/staff/view/loads/staff_loads_view.dart';
import 'package:uscitylink/views/staff/widgets/load_guard.dart';
import 'package:uscitylink/views/staff/widgets/chat_load_sender.dart';

class FakeApi extends StaffApiClient {
  final calls = <String>[];
  final Map<String, dynamic> Function(String method, String path, Object? body) handler;
  FakeApi(this.handler);
  Future<Map<String, dynamic>> _h(String m, String p, [Object? b]) async {
    calls.add('$m $p ${b ?? ''}');
    return handler(m, p, b);
  }

  @override
  Future<Map<String, dynamic>> get(String path, [Map<String, dynamic>? query]) => _h('GET', path, query);
  @override
  Future<Map<String, dynamic>> post(String path, [Object? body]) => _h('POST', path, body);
  @override
  Future<Map<String, dynamic>> patch(String path, [Object? body]) => _h('PATCH', path, body);
  @override
  Future<Map<String, dynamic>> put(String path, [Object? body]) => _h('PUT', path, body);
  @override
  Future<Map<String, dynamic>> delete(String path) => _h('DELETE', path);
}

Map<String, dynamic> leg(int id, int no, String status, {String? driver = 'p1', String? trip}) => {
      'id': id, 'load_id': 7, 'leg_no': no, 'trip_no': trip ?? '1011${no > 1 ? '-$no' : ''}', 'status': status, 'driver_profile_id': driver, 'truck_number': '101',
      'stops': [
        {'id': id * 10, 'seq': 1, 'type': 'pickup', 'city': 'Chandigarh', 'state': 'PB', 'appointment_local': '2026-11-12T08:00'},
        {'id': id * 10 + 1, 'seq': 2, 'type': 'drop', 'city': 'Ambala', 'state': 'HR'},
      ],
    };

Map<String, dynamic> loadJson(List<Map<String, dynamic>> legs, {String status = 'active'}) =>
    {'id': 7, 'load_no': '1011', 'invoice_no': '1011', 'track_token': 'tok', 'type': legs.length > 1 ? 'relay' : 'direct', 'status': status, 'created_at': '2026-11-12T10:00:00Z', 'legs': legs};

void main() {
  test('load text: a load without Load # is blocked, with it is allowed', () {
    const noNo = 'TEMP# REFER BILLS\n\nPICKUP#\nSignature Brands\n1299 SW 49th Avenue\nOCALA, FL 34474\n11/13/2026 12:00PM\n\nDELIVERY#\nWALMART DC\n10817 HWY 99W\nRED BLUFF, CA 96080';
    expect(looksLikeLoad(noNo), true);
    expect(loadMissingNo(noNo), true);
    expect(loadMissingNo('LOAD # 1011\n$noNo'), false);
    expect(loadNoIn('INVOICE #: 55-ab'), '55-AB');
    expect(loadMissingNo('hello driver'), false);
    const waco = 'AFTER GETTING EMPTY, GO TO WACO, TX AND PICKUP EMPTY TRAILER# 13065 AND DROP IT TO NEARBY THERMO KING. \n\nADDRESS FOR WACO, TX\n\nWACO PROCESSING\n301 AVIATION PARKWAY\nWACO, TX 76705\n\n\nTRAILER# 13065\n\nTHERMO KING ADDRESS : \n\nConvoy Servicing - Thermo King of Temple\n575 Northpoint Dr, \nTemple, TX, 76501';
    expect(loadMissingNo(waco), true, reason: 'address + pickup / drop words → needs its Load #');
    expect(loadMissingNo('LOAD # 1011\n$waco'), false);
    expect(loadMissingNo('Did you deliver yet?'), false);
    expect(loadMissingNo('Delivered, OK thanks'), false);
    expect(loadMissingNo('pickup at Walmart Fresno, CA tomorrow 5am'), true);
  });

  testWidgets('list shows the Load #, type, created date, legs and opens the filters', (tester) async {
    final api = FakeApi((m, p, b) => {
          'data': {
            'loads': [loadJson([leg(1, 1, 'ended'), leg(2, 2, 'rolling', driver: 'p2')])],
            'total': 1,
            'counts': {'active': 1, 'transfer': 0},
            'driverNames': {'p1': 'Raj Singh', 'p2': 'Aman Kumar'},
          }
        });
    await tester.pumpWidget(GetMaterialApp(home: StaffLoadsView(service: LoadsService(api))));
    await tester.pumpAndSettle();
    expect(find.text('Load 1011'), findsOneWidget);
    expect(find.text('Transfer  ·  2 legs  ·  Added Nov 12, 2026'), findsOneWidget);
    expect(find.textContaining('Raj Singh'), findsOneWidget);
    expect(find.text('Chandigarh, PB'), findsOneWidget);
    expect(find.text('Ambala, HR'), findsOneWidget);
    expect(find.text('PICKUP'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('tab_active')), 100, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('tab_active')));
    await tester.pumpAndSettle();
    expect(api.calls.last, contains('status: active'));
  });

  testWidgets('detail: End load on a rolling leg, and multi-leg Mark completed lists each leg + Mark all', (tester) async {
    var legs = [leg(1, 1, 'ended'), leg(2, 2, 'ended', driver: 'p2')];
    final api = FakeApi((m, p, b) {
      if (m == 'GET' && p == 'loads/7') {
        return {'data': {'load': loadJson(legs, status: 'delivered'), 'legs': legs, 'segments': [], 'history': [], 'driverNames': {'p1': 'Raj Singh', 'p2': 'Aman Kumar'}, 'yardVisits': [], 'milesTotals': {'miles': 0, 'missing': 0}}};
      }
      return {'message': 'ok'};
    });
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(home: StaffLoadDetailView(loadId: 7, service: LoadsService(api))));
    await tester.pumpAndSettle();
    expect(find.text('Code 1011'), findsOneWidget);
    await tester.tap(find.byKey(const Key('markCompleted')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('completeDialog')), findsOneWidget);
    expect(find.byKey(const Key('completeLeg_1')), findsOneWidget);
    expect(find.byKey(const Key('completeLeg_2')), findsOneWidget);
    await tester.tap(find.byKey(const Key('completeAll')));
    await tester.pumpAndSettle();
    expect(api.calls.where((c) => c.contains('trips/1/action') || c.contains('trips/2/action')).length, 2);

    legs = [leg(1, 1, 'rolling')];
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(GetMaterialApp(home: StaffLoadDetailView(loadId: 7, service: LoadsService(api))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('end_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End load').last);
    await tester.pumpAndSettle();
    expect(api.calls.any((c) => c.startsWith('POST loads/7/legs/1/end')), true);
  });

  testWidgets('add load: Load # lookup note says leg 2; Send now asks to end the previous leg, then sends', (tester) async {
    var sends = 0;
    final api = FakeApi((m, p, b) {
      if (p == 'loads/lookup') {
        return {'data': {'loadNo': '1011', 'load': {'id': 7}, 'nextLegNo': 2, 'prev': {'tripId': 1, 'legNo': 1, 'tripNo': '1011', 'status': 'rolling', 'open': true, 'driverName': 'Raj Singh', 'truck': '101', 'from': 'Chandigarh', 'to': 'Ambala'}}};
      }
      if (p == 'trips/trucks') {
        return {'data': [{'truck': '202', 'drivers': [{'id': 'p2', 'name': 'Aman Kumar'}]}]};
      }
      if (p == 'loads') {
        final body = b as Map;
        sends++;
        if (body['endPrevious'] != true) throw StaffApiError('Leg 1 still open', 409, {'needs': 'endPrevious', 'info': {'prev': {'tripId': 1, 'legNo': 1, 'tripNo': '1011', 'status': 'rolling', 'open': true, 'driverName': 'Raj Singh', 'from': 'Chandigarh', 'to': 'Ambala'}}});
        return {'message': 'Load sent'};
      }
      return {'data': {}};
    });
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(home: StaffAddLoadView(service: LoadsService(api))));
    await tester.enterText(find.byKey(const Key('loadNo')), '1011');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.textContaining('this is leg 2'), findsOneWidget);
    expect(find.textContaining("hasn't ended leg 1"), findsOneWidget);
    await tester.tap(find.byKey(const Key('truckField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Truck 202'));
    await tester.pumpAndSettle();
    // fill both stops' city/state
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ambala');
    await tester.enterText(fields.at(1), 'HR');
    await tester.enterText(fields.at(2), 'Delhi');
    await tester.enterText(fields.at(3), 'DL');
    await tester.ensureVisible(find.byKey(const Key('sendNow')));
    await tester.tap(find.byKey(const Key('sendNow')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Leg 1 is still open'), findsOneWidget);
    await tester.tap(find.text('End & send'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(sends, 2);
  });

  testWidgets('detail: review warning, live tracking, Edit opens the prefilled form and saves', (tester) async {
    final l1 = {...leg(1, 1, 'rolling'), 'needs_review': 1, 'review_notes': '1 delivery without an appointment time', 'trailer_numbers': '10010', 'temperature': '34 CONT.'};
    final api = FakeApi((m, p, b) {
      if (p == 'loads/7') return {'data': {'load': loadJson([l1]), 'legs': [l1], 'segments': [], 'history': [], 'driverNames': {'p1': 'Raj Singh'}, 'yardVisits': [], 'milesTotals': {'miles': 0, 'missing': 0}}};
      if (p == 'trips/1/live') {
        return {'data': {'truck': {'speedMph': 0, 'address': '5623 East Olympic Blvd', 'at': DateTime.now().toIso8601String(), 'fuelPercent': 82, 'engine': 'Idle'}, 'miles': 2044, 'driveMinutes': 2045, 'restMinutes': 2000, 'eta': '2026-11-16T14:50:00Z', 'fuelGallons': 314, 'stops': [], 'plan': {'googleMinutes': 1793, 'drivingMinutes': 2045, 'breakMinutes': 60, 'restMinutes': 1800, 'fuelMinutes': 120, 'totalMinutes': 4025, 'stops': []}}};
      }
      if (p == 'trips/trucks') return {'data': []};
      return {'message': 'ok'};
    });
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(home: StaffLoadDetailView(loadId: 7, service: LoadsService(api))));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Check this load before the driver relies on it:'), findsOneWidget);
    expect(find.text('• 1 delivery without an appointment time'), findsOneWidget);
    expect(find.text('Live tracking'), findsOneWidget);
    expect(find.text('82%'), findsOneWidget);
    expect(find.byKey(const Key('etaPlan')), findsOneWidget);
    expect(find.byKey(const Key('hold_1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit_1')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Edit load'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    await tester.tap(find.byKey(const Key('saveEdit')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(api.calls.any((c) => c.startsWith('PATCH trips/1') && c.contains('needsReview: false')), true);
  });

  testWidgets('chat box: a load without Load # is not sent; the dialog adds the LOAD # line', (tester) async {
    final input = TextEditingController();
    final sent = <String>[];
    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: Column(children: [
          TextField(controller: input, maxLines: 5),
          ElevatedButton(
            key: const Key('send'),
            onPressed: () {
              if (blockLoadWithoutNo(input)) return;
              sent.add(input.text);
            },
            child: const Text('Send'),
          ),
        ]),
      ),
    ));
    input.text = 'PICKUP#\nSYSCO\n150 Main St\nSALINAS, CA 93901\n11/12/2026 06:00AM\n\nDELIVERY#\nCOSTCO\n5900 Stewart Ave\nFREMONT, CA 94538\n11/12/2026 06:00PM';
    await tester.tap(find.byKey(const Key('send')));
    await tester.pumpAndSettle();
    expect(sent, isEmpty);
    expect(find.text('Load # missing — not sent'), findsOneWidget);
    await tester.tap(find.byKey(const Key('addLoadNoLine')));
    await tester.pumpAndSettle();
    expect(input.text.startsWith('LOAD # \nPICKUP#'), true);
    input.text = input.text.replaceFirst('LOAD # ', 'LOAD # 1011');
    await tester.tap(find.byKey(const Key('send')));
    await tester.pumpAndSettle();
    expect(sent.length, 1, reason: 'with the Load # it goes');
    // pickup / drop words with an address, any format: blocked too
    input.text = 'GO PICK UP EMPTY TRAILER 13065 AT\nWACO PROCESSING\n301 AVIATION PARKWAY\nWACO, TX 76705\nDROP IT AT\n575 Northpoint Dr\nTemple, TX, 76501';
    await tester.tap(find.byKey(const Key('send')));
    await tester.pumpAndSettle();
    expect(sent.length, 1);
    expect(find.text('Load # missing — not sent'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    // ordinary chat goes
    input.text = 'Did you deliver yet?';
    await tester.tap(find.byKey(const Key('send')));
    await tester.pumpAndSettle();
    expect(sent.length, 2);
  });

  testWidgets('miles from GPS are labelled; Re-check miles asks the server again', (tester) async {
    final ended = {...leg(1, 1, 'ended'), 'started_at': '2026-11-11T09:00:00Z', 'ended_at': '2026-11-11T15:40:00Z', 'total_mileage': '200.4', 'miles_source': 'gps'};
    final noGps = {...leg(2, 2, 'ended', driver: 'p2'), 'ended_at': '2026-11-11T19:00:00Z', 'miles_note': 'No GPS match — check times / type miles'};
    final api = FakeApi((m, p, b) {
      if (p == 'loads/7') return {'data': {'load': loadJson([ended, noGps], status: 'delivered'), 'legs': [ended, noGps], 'segments': [], 'history': [], 'driverNames': {'p1': 'Raj Singh', 'p2': 'Aman Kumar'}, 'yardVisits': [], 'milesTotals': {'miles': 200.4, 'missing': 1}}};
      return {'message': 'Miles re-checked from the truck\'s GPS: 150 mi'};
    });
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(home: StaffLoadDetailView(loadId: 7, service: LoadsService(api))));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('200.4 mi · Samsara · times from GPS'), findsOneWidget);
    expect(find.text('No GPS match — check times / type miles'), findsOneWidget);
    await tester.tap(find.byKey(const Key('recheck_2')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(api.calls.any((c) => c.startsWith('POST loads/7/legs/2/match-gps')), true);
  });

  testWidgets('add load: same Load # already lined up → note, then Replace dialog with End current & send', (tester) async {
    final bodies = <Map>[];
    final lined = {'tripId': 9, 'legNo': 1, 'tripNo': '2001', 'status': 'scheduled', 'open': true, 'driverName': 'Raj Singh', 'truck': '101', 'from': 'Fresno, CA', 'to': 'Reno, NV'};
    final current = {'tripId': 5, 'legNo': 1, 'tripNo': '1990', 'status': 'rolling', 'open': true, 'driverName': 'Aman Kumar', 'from': 'Ambala, HR', 'to': 'Delhi, DL'};
    final api = FakeApi((m, p, b) {
      if (p == 'loads/lookup') return {'data': {'loadNo': '2001', 'load': {'id': 7}, 'nextLegNo': 1, 'linedUp': lined}};
      if (p == 'trips/trucks') return {'data': [{'truck': '202', 'drivers': [{'id': 'p2', 'name': 'Aman Kumar'}]}]};
      if (p == 'loads') {
        final body = Map.from(b as Map);
        bodies.add(body);
        if (body['replace'] != true) throw StaffApiError('Load 2001 is already lined up', 409, {'needs': 'replaceLinedUp', 'info': {'linedUp': lined, 'current': current}});
        return {'message': 'Load sent'};
      }
      return {'data': {}};
    });
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(home: StaffAddLoadView(service: LoadsService(api))));
    await tester.enterText(find.byKey(const Key('loadNo')), '2001');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.textContaining('is already lined up for Raj Singh'), findsOneWidget);
    await tester.tap(find.byKey(const Key('truckField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Truck 202'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Fresno');
    await tester.enterText(fields.at(1), 'CA');
    await tester.enterText(fields.at(2), 'Reno');
    await tester.enterText(fields.at(3), 'NV');
    await tester.ensureVisible(find.byKey(const Key('sendNow')));
    await tester.tap(find.byKey(const Key('sendNow')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('replaceLinedUpDialog')), findsOneWidget);
    expect(find.text('Load 2001 is already lined up'), findsOneWidget);
    expect(find.byKey(const Key('replaceDriverBusy')), findsOneWidget);
    expect(find.text('Replace & line up after #1990'), findsOneWidget);
    await tester.tap(find.byKey(const Key('answerReplaceEndCurrent')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(bodies.length, 2);
    expect(bodies.last['replace'], true);
    expect(bodies.last['endDriverCurrent'], true);
    expect(bodies.last['send'], true);
  });

  testWidgets('chat box: a pasted load is sent as a load (not a message); driver busy → Line up sends lineUp', (tester) async {
    const text = 'Load #: 0055926\n\nPickup#\nWayne Farms - Albertville\n700 McDonald Ave.\nALBERTVILLE, AL 35950\n\nDrop#\nROMA SOUTHERN CALIFORNIA\n16639 East Gale Ave\nCITY OF INDUSTRY, CA 91745\n11/15/2026 07:00AM';
    final bodies = <Map>[];
    ChatLoadSender.service = LoadsService(FakeApi((m, p, b) {
      if (p == 'loads/from-text') {
        final body = Map.from(b as Map);
        bodies.add(body);
        if (body['lineUp'] != true) {
          throw StaffApiError('busy', 409, {'needs': 'driverBusy', 'info': {'current': {'tripId': 5, 'legNo': 1, 'tripNo': '1990', 'status': 'rolling', 'open': true, 'driverName': 'Raj Singh', 'from': 'Ambala, HR', 'to': 'Delhi, DL'}}});
        }
        return {'message': 'Load 0055926 lined up'};
      }
      return {};
    }));
    expect(ChatLoadSender.isLoad(text), true);
    expect(ChatLoadSender.isLoad('hello driver'), false);
    bool? done;
    await tester.pumpWidget(GetMaterialApp(
      home: Builder(builder: (ctx) => Scaffold(body: ElevatedButton(key: const Key('go'), onPressed: () async => done = await ChatLoadSender.send(ctx, text, 'p1'), child: const Text('go')))),
    ));
    await tester.tap(find.byKey(const Key('go')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chatLoadDriverBusy')), findsOneWidget);
    expect(find.text('Raj Singh is on another load'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chatLoadLineUp')));
    await tester.pumpAndSettle();
    expect(bodies.length, 2);
    expect(bodies.first['text'], text);
    expect(bodies.first['driverProfileId'], 'p1');
    expect(bodies.last['lineUp'], true);
    expect(done, true);
    // let the "Load lined up" snackbar show and leave (4 s + its animation)
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 2));
  });
}
