import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/firebase_options.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/background_service.dart';
import 'package:uscitylink/services/fcm_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final socketService = Get.put(SocketService());

  String? accessToken = await UserPreferenceController().getToken();

  if (accessToken != null) {
    socketService.connectSocket();
    final fcmService = Get.put(FCMService());

    // Explicitly update the FCM token after login
    String? token = fcmService.fcmToken.value;
    if (token != null && token.isNotEmpty) {
      await fcmService.updateDeviceToken(token);
    }
  }

  Get.lazyPut(() => MessageController());
  BackgroundService.start();
  // Set the status bar color (Android only)
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.blue, // Set your color here
    statusBarIconBrightness:
        Brightness.light, // Set icon brightness: light or dark
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
