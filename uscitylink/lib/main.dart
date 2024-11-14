import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/route_manager.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 1: Initialize SocketService
  final socketService = Get.put(SocketService());

  // Step 2: Get the access token if it exists
  String? accessToken = await UserPreferenceController().getToken();

  // Step 3: If the token exists, connect to the socket
  if (accessToken != null) {
    socketService.connectSocket();
  }

  // Step 4: Lazily load the MessageController
  Get.lazyPut(() => MessageController());

  // Step 5: Run the app
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
