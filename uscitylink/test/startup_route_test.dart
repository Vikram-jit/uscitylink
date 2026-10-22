import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/views/update_view.dart';

/// Reopening the app with a saved login must always leave the splash screen, whatever the
/// version check or the server answers. It used to hang when the build was marked Active.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pkg = MethodChannel('dev.fluttercommunity.plus/package_info');

  setUp(() {
    Get.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pkg, (call) async => {
          'appName': 'USCityLink',
          'packageName': 'com.uscitylink',
          'version': '1.3.22',
          'buildNumber': '1',
          'buildSignature': '',
        });
  });

  Future<String?> openApp(
    WidgetTester tester, {
    required String savedRole,
    required http.Response Function(http.Request) server,
  }) async {
    SharedPreferences.setMockInitialValues({'token': 'saved-token', 'role': savedRole});
    Get.put(SocketService());
    Widget page(String name) => Scaffold(body: Text(name));
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: AppRoutes.splashView,
      getPages: [
        GetPage(name: AppRoutes.splashView, page: () => page('splash')),
        GetPage(name: AppRoutes.login, page: () => page('login')),
        GetPage(name: AppRoutes.staff_dashboard, page: () => page('staff')),
        GetPage(name: AppRoutes.driverDashboard, page: () => page('driver')),
        GetPage(name: AppRoutes.securityDashboard, page: () => page('security')),
      ],
    ));
    await http.runWithClient(() async {
      Get.put(LoginController()).checkRole();
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(seconds: 3)); // the 1 s Timer before navigating, 2 s prompt
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
    }, () => MockClient((req) async => server(req)));
    return Get.currentRoute;
  }

  http.Response json(Object body, [int code = 200]) => http.Response(jsonEncode(body), code);
  http.Response Function(http.Request) profileThen(String role, Object versionAnswer) => (req) {
        if (req.url.path.endsWith('/user/profile')) {
          return json({'status': true, 'data': {'id': 'p1', 'username': 'Test', 'role': {'name': role}}});
        }
        if (req.url.path.endsWith('/auth/updateAppVersion')) return json(versionAnswer);
        return json({'status': true, 'data': {}});
      };

  for (final answer in ['UpToDate', 'Update', 'NewVersion']) {
    testWidgets('staff, version check says $answer → staff dashboard', (tester) async {
      final route = await openApp(tester,
          savedRole: 'staff', server: profileThen('staff', {'status': true, 'data': answer}));
      expect(route, AppRoutes.staff_dashboard);
    });
  }

  testWidgets('driver, build marked Active (UpToDate) → driver dashboard', (tester) async {
    final route = await openApp(tester,
        savedRole: 'driver', server: profileThen('driver', {'status': true, 'data': 'UpToDate'}));
    expect(route, AppRoutes.driverDashboard);
  });

  testWidgets('admin → staff dashboard even if the version check fails', (tester) async {
    final route = await openApp(tester,
        savedRole: 'admin', server: profileThen('admin', {'status': false, 'message': 'boom'}));
    expect(route, AppRoutes.staff_dashboard);
  });

  testWidgets('server error on the profile → saved role dashboard, not a stuck loader', (tester) async {
    final route = await openApp(tester,
        savedRole: 'driver', server: (_) => json({'status': false, 'message': 'Internal Server Error'}, 500));
    expect(route, AppRoutes.driverDashboard);
  });

  Map<String, dynamic> v2(String status, {bool notes = true}) => {
        'status': true,
        'data': {
          'status': status,
          'latest': {'version': '1.3.23', 'buildNumber': 4, 'releaseNotes': notes ? 'Faster chat' : null},
          'required': status == 'ForceUpdate' ? {'version': '1.3.23', 'buildNumber': 4} : null,
        },
      };

  testWidgets('forced update → update screen instead of the dashboard, back is blocked', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await openApp(tester, savedRole: 'driver', server: profileThen('driver', v2('ForceUpdate')));
    expect(find.byType(UpdateView), findsOneWidget);
    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('1.3.22 (1)'), findsOneWidget); // installed
    expect(find.text('1.3.23 (4)'), findsOneWidget); // latest
    expect(find.text('Faster chat'), findsOneWidget);
    expect(find.text('driver'), findsNothing);

    await tester.binding.handlePopRoute(); // Android back button
    await tester.pumpAndSettle();
    expect(find.byType(UpdateView), findsOneWidget);
  });

  testWidgets('update available → dashboard opens, then a dismissible prompt once', (tester) async {
    final route = await openApp(tester, savedRole: 'staff', server: profileThen('staff', v2('UpdateAvailable')));
    expect(route, AppRoutes.staff_dashboard);
    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Version 1.3.23 (4) is available.'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.text('Update available'), findsNothing);
    expect(find.text('staff'), findsOneWidget);
  });

  testWidgets('admin lifts the force → "check again" leaves the update screen', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    var answer = 'ForceUpdate';
    http.Response server(http.Request req) => profileThen('driver', v2(answer))(req);
    await openApp(tester, savedRole: 'driver', server: server);
    expect(find.byType(UpdateView), findsOneWidget);

    answer = 'UpToDate';
    await http.runWithClient(() async {
      await tester.tap(find.text("I've updated — check again"));
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pumpAndSettle();
    }, () => MockClient((req) async => server(req)));
    expect(find.byType(UpdateView), findsNothing);
    expect(Get.currentRoute, AppRoutes.splashView);
  });
}
