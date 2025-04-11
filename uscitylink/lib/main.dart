import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/firebase_options.dart';
import 'package:uscitylink/hive/hive_adapters.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    ..registerAdapter(UserChannelModelAdapter());

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final socketService = Get.put(SocketService());

  String? accessToken = await UserPreferenceController().getToken();

  if (accessToken != null) {
    socketService.connectSocket();

    // Explicitly update the FCM token after login
    // String? token = fcmService.fcmToken.value;
    // if (token != null && token.isNotEmpty) {
    //   await fcmService.updateDeviceToken(token);
    // }
    Get.lazyPut(() => MessageController());
  }
  //BackgroundService.start();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.blue, // Set your color here
    statusBarIconBrightness: Brightness.light,
  ));
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
    );
  }
}
