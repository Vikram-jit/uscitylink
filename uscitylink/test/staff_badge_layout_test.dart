import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

void main() {
  testWidgets('count badge stays small as a ListTile trailing widget (drawer)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 304, // drawer width
          child: Column(children: [
            ListTile(title: const Text('System messages'), trailing: const StaffCountBadge(count: 3)),
            ListTile(title: const Text('Scale checks'), trailing: const StaffCountBadge(count: 120)),
          ]),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(StaffCountBadge).first);
    expect(size.width, lessThan(40));
    expect(size.height, 22);
    expect(find.text('99+'), findsOneWidget);
  });
}
