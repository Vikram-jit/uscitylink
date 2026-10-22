import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uscitylink/model/staff/staff_dashboard_model.dart';
import 'package:uscitylink/views/staff/view/staff_dashboard.dart';

void main() {
  testWidgets('staff dashboard shows the counts and every tile still goes to its screen', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final tapped = <String>[];
    VoidCallback cb(String name) => () => tapped.add(name);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StaffDashboardBody(
          data: StaffDashboardModel(userUnMessage: 17, driverCount: 248, truckGroupCount: 63, templateCount: 12, trainingCount: 9, staffGroupCount: 3, alertGroupCount: 1),
          loading: false,
          name: 'Gurvinder Singh',
          role: 'admin',
          channelName: 'U S CITYLINK INC',
          connected: true,
          pendingScaleChecks: 2,
          unreadSystemMessages: 5,
          onScaleChecks: cb('scaleChecks'),
          onSystemMessages: cb('systemMessages'),
          onRefresh: () async {},
          onMenu: cb('menu'),
          onOpenChats: cb('chats'),
          onDrivers: cb('drivers'),
          onTemplates: cb('templates'),
          onTrainings: cb('trainings'),
          onTruckGroups: cb('truckGroups'),
          onStaffGroup: cb('staffGroup'),
          onAlertGroup: cb('alertGroup'),
          onAddDriver: cb('addDriver'),
          onAllDrivers: cb('allDrivers'),
          onChannels: cb('channels'),
        ),
      ),
    ));

    // Admin is shown as an admin, with their first name
    expect(find.text('Gurvinder'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    for (final value in ['17', '248', '63', '12', '9', '2', '5']) {
      expect(find.text(value), findsOneWidget);
    }

    for (final entry in {
      'Scale checks': 'scaleChecks',
      'System messages': 'systemMessages',
      'Open': 'chats',
      'Drivers': 'drivers',
      'Truck groups': 'truckGroups',
      'Templates': 'templates',
      'Training videos': 'trainings',
      'Staff group': 'staffGroup',
      'Alert group': 'alertGroup',
      'Add driver': 'addDriver',
      'All drivers': 'allDrivers',
      'Channels': 'channels',
    }.entries) {
      await tester.ensureVisible(find.text(entry.key));
      await tester.tap(find.text(entry.key));
      expect(tapped.last, entry.value, reason: '"${entry.key}" should open ${entry.value}');
    }
    await tester.tap(find.byTooltip('Menu'));
    expect(tapped.last, 'menu');
  });
}
