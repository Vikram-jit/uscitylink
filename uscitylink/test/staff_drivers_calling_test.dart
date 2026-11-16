import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/staff/staffdriver_controller.dart';
import 'package:uscitylink/model/staff/driver_pagination_model.dart';
import 'package:uscitylink/services/staff/staff_api_client.dart';
import 'package:uscitylink/views/staff/view/staff_driver_view.dart';

class FakeApi extends StaffApiClient {
  final puts = <String>[];
  bool fail = false;
  @override
  Future<Map<String, dynamic>> put(String path, [Object? body]) async {
    puts.add('$path $body');
    if (fail) throw StaffApiError('Calling is switched on for drivers only', 400);
    return {'status': true};
  }
}

DriverPaginationModel page() => DriverPaginationModel.fromJson({
      'driver': [
        {'id': 'p1', 'username': 'Raj Singh', 'status': 'active', 'user': {'id': 'u1', 'driver_number': '101', 'email': 'raj@x.com', 'phone_number': '555', 'calls_enabled': true}},
        {'id': 'p2', 'username': 'Aman Kumar', 'status': 'active', 'user': {'id': 'u2', 'driver_number': '102', 'email': 'aman@x.com', 'phone_number': '556', 'calls_enabled': false}},
      ],
      'pagination': {'currentPage': 1, 'pageSize': 20, 'total': 2, 'totalPages': 1},
    });

void main() {
  Future<(StaffDriverController, FakeApi)> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi();
    final c = StaffDriverController(loadPage: (_) async => page(), api: api);
    await tester.pumpWidget(GetMaterialApp(home: StaffDriverView(controller: c)));
    await tester.pump(const Duration(milliseconds: 300));
    return (c, api);
  }

  test('the model reads the calling flag (default off)', () {
    final d = page().driver!;
    expect(d[0].user!.callsEnabled, true);
    expect(d[1].user!.callsEnabled, false);
    expect(User.fromJson({'id': 'x'}).callsEnabled, false);
  });

  testWidgets('drivers with calling on show a phone icon; the Calling switch is in each driver\'s details', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('callingOn_p1')), findsOneWidget);
    expect(find.byKey(const Key('callingOn_p2')), findsNothing);
    await tester.tap(find.text('Aman Kumar (102)'));
    await tester.pumpAndSettle();
    expect(find.text('Lets this driver call dispatch from the app. Staff can always call drivers.'), findsOneWidget);
    expect(tester.widget<Switch>(find.byKey(const Key('callingSwitch_p2'))).value, false);
  });

  testWidgets('switching it on sends PUT calls/drivers/<id> and shows the icon at once', (tester) async {
    final (c, api) = await open(tester);
    await tester.tap(find.text('Aman Kumar (102)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('callingSwitch_p2')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(api.puts, ['calls/drivers/p2 {enabled: true}']);
    expect(c.drivers[1].user!.callsEnabled, true);
    expect(find.byKey(const Key('callingOn_p2')), findsOneWidget);
    expect(tester.widget<Switch>(find.byKey(const Key('callingSwitch_p2'))).value, true);
    // …and off again for the other one
    await tester.tap(find.text('Raj Singh (101)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('callingSwitch_p1')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(api.puts.last, 'calls/drivers/p1 {enabled: false}');
    expect(find.byKey(const Key('callingOn_p1')), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('if the server says no, the switch goes back and the reason is shown', (tester) async {
    final (c, api) = await open(tester);
    api.fail = true;
    await tester.tap(find.text('Aman Kumar (102)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('callingSwitch_p2')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.drivers[1].user!.callsEnabled, false, reason: 'put back');
    expect(find.byKey(const Key('callingOn_p2')), findsNothing);
    expect(tester.widget<Switch>(find.byKey(const Key('callingSwitch_p2'))).value, false);
    expect(find.textContaining('drivers only'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 2));
  });
}
