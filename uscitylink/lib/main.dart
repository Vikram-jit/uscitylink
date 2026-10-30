import 'dart:ui' show PlatformDispatcher;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:uscitylink/services/app_update_service.dart';
import 'package:uscitylink/services/call/call_kit.dart';
import 'package:uscitylink/services/call/call_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/firebase_options.dart';
import 'package:uscitylink/hive/hive_adapters.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/network_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/closed_box_guard.dart';
import 'package:uscitylink/utils/theme/theme.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Logout deletes every Hive box. Any request that finishes afterwards and tries to cache its
  // result hits a closed box; that is expected (the cache write is simply skipped), not a crash.
  final previousOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    if (isClosedBoxError(error)) {
      debugPrint('ℹ️ Skipped a cache write after logout: $error');
      return true;
    }
    return previousOnError?.call(error, stack) ?? false;
  };
  await pdfrxFlutterInitialize(); // Required when using engine APIs before widgets
  await Hive.initFlutter();

  Hive
    ..registerAdapter(DashboardModelAdapter())
    ..registerAdapter(ChannelAdapter())
    ..registerAdapter(LatestGroupMessageAdapter())
    ..registerAdapter(GroupDashboardAdapter())
    ..registerAdapter(SenderModelAdapter())
    ..registerAdapter(LatestMessageAdapter())
    ..registerAdapter(MessageModelAdapter())
    ..registerAdapter(GroupAdapter())
    ..registerAdapter(GroupChannelAdapter())
    ..registerAdapter(ChannelModelAdapter())
    ..registerAdapter(UserModelAdapter())
    ..registerAdapter(CountModelAdapter())
    ..registerAdapter(GroupModelAdapter())
    ..registerAdapter(UserChannelModelAdapter())
    ..registerAdapter(RouteModelAdapter())
    ..registerAdapter(TrucksAdapter())
    ..registerAdapter(VehicleModelAdapter())
    ..registerAdapter(StationsAdapter())
    ..registerAdapter(FuelPriceAdapter())
    ..registerAdapter(VehicleGpsModelAdapter());

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Rings for voice calls while the app is closed (Android FCM data; other messages are untouched)
  FirebaseMessaging.onBackgroundMessage(callFirebaseBackgroundHandler);

  final socketService = Get.put(SocketService());

  String? accessToken = await UserPreferenceController().getToken();

  socketService.connectSocket();

  // Voice calls: socket/push/CallKit wiring (after the socket service exists)
  if (accessToken != null && accessToken.isNotEmpty) Get.put(CallService(), permanent: true);

  // Explicitly update the FCM token after login
  // String? token = fcmService.fcmToken.value;
  // if (token != null && token.isNotEmpty) {
  //   await fcmService.updateDeviceToken(token);
  // }
  if (!Get.isRegistered<MessageController>()) {
    Get.lazyPut(() => MessageController());
    print('📡 MessageController registered');
  }
  if (!Get.isRegistered<NetworkService>()) {
    Get.lazyPut(() => NetworkService());
    print('📡 NetworkService registered');
  }
  //BackgroundService.start();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.blue, // Set your color here
    statusBarIconBrightness: Brightness.light,
  ));

  // Version check on resume (forced update screen / update available prompt)
  Get.put(AppUpdateService(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ChatBox USCityLink',
      themeMode: ThemeMode.light,
      theme: TAppTheme.lightTheme,
      // darkTheme: TAppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splashView,
      getPages: AppRoutes.routes,
      navigatorObservers: [routeObserver],
    );
  }
}
