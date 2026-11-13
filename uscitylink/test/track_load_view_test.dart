import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:uscitylink/views/trip/track_load_view.dart';

/// "Track a load" from the login screen (lib/views/trip/track_load_view.dart).
void main() {
  final live = {
    'status': true,
    'data': {
      'expired': false,
      'loadNo': '1011',
      'phase': 'in_transit',
      'status': 'active',
      'eta': '2026-11-12T18:25:00.000Z',
      'lateMinutes': 25,
      'equipment': {'truck': '24565', 'trailer': '10265', 'temperature': '34 CONT.'},
      'stops': [
        {'id': 1, 'type': 'pickup', 'name': 'TAYLOR FARMS', 'place': 'SALINAS, CA', 'address': '150 Main St, SALINAS, CA 93901', 'appointment': '2026-11-12T06:00', 'arrivedAt': '2026-11-12T13:55:00.000Z', 'departedAt': '2026-11-12T14:55:00.000Z', 'state': 'done'},
        {'id': 2, 'type': 'drop', 'name': 'SYSCO SAN FRANCISCO', 'place': 'FREMONT, CA', 'address': '5900 Stewart Ave, FREMONT, CA 94538', 'appointment': '2026-11-12T18:00', 'state': 'next'},
      ],
      'live': {
        'truck': null,
        'stops': [],
        'path': [],
        'miles': 62,
        'eta': '2026-11-12T18:25:00.000Z',
        'breaks': [
          {'kind': 'break', 'minutes': 30, 'at': '2026-11-12T16:00:00.000Z', 'atMile': 480},
        ],
      },
      'activity': [
        {'at': '2026-11-12T14:55:00.000Z', 'text': 'Picked up — in transit'},
        {'at': '2026-11-12T10:00:00.000Z', 'text': 'Load booked'},
      ],
    },
  };

  Future<void> open(WidgetTester tester, Map<String, dynamic> Function(String code) answer) async {
    await tester.pumpWidget(GetMaterialApp(home: TrackLoadView(fetcher: (code) async => answer(code))));
  }

  testWidgets('a short code shows the load: steps, late badge, shipment, breaks, stops, activity', (tester) async {
    String? asked;
    await open(tester, (code) {
      asked = code;
      return live;
    });
    await tester.enterText(find.byKey(const Key('trackCodeInput')), '0056033');
    await tester.tap(find.byKey(const Key('trackButton')));
    await tester.pumpAndSettle();
    expect(asked, '0056033', reason: 'sent exactly as typed');
    expect(find.text('LOAD 1011'), findsOneWidget);
    expect(find.textContaining('Arriving'), findsOneWidget);
    expect(find.text('Running 25 min late'), findsOneWidget);
    expect(find.byKey(const Key('trackSteps')), findsOneWidget);
    expect(find.text('Truck 24565 · Trailer 10265'), findsOneWidget);
    expect(find.text('62 miles to go'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('trackBreaks')), 200, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('30-min break'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('SYSCO SAN FRANCISCO'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('DELIVERY · NEXT'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Picked up — in transit'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Load booked'), findsOneWidget);
  });

  testWidgets('a completed load: the code has expired', (tester) async {
    await open(tester, (_) => {
          'status': true,
          'data': {'expired': true, 'loadNo': '1011', 'status': 'completed', 'deliveredAt': '2026-11-12T18:20:00.000Z'},
        });
    await tester.enterText(find.byKey(const Key('trackCodeInput')), '56033');
    await tester.tap(find.byKey(const Key('trackButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trackExpired')), findsOneWidget);
    expect(find.text('Load 1011 is completed'), findsOneWidget);
    expect(find.textContaining('This tracking has expired'), findsOneWidget);
  });

  testWidgets('a wrong code says so; a too-short one asks for the code', (tester) async {
    await open(tester, (_) => {'status': false, 'message': 'No load found with that tracking code'});
    await tester.enterText(find.byKey(const Key('trackCodeInput')), '12');
    await tester.tap(find.byKey(const Key('trackButton')));
    await tester.pump();
    expect(find.textContaining('type your load number first'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('trackCodeInput')), '99999');
    await tester.tap(find.byKey(const Key('trackButton')));
    await tester.pumpAndSettle();
    expect(find.text('No load found with that tracking code'), findsOneWidget);
  });
}
