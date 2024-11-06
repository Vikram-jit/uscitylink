import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/route_manager.dart';
import 'package:uscitylink/controller/loading_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/utils/theme/theme.dart';
import 'package:uscitylink/views/auth/login_view.dart';

void main() {
  Get.put(LoadingController()); // This makes the controller available globally
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ChatBox USCityLink',
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      getPages: AppRoutes.routes,
    );
  }
}
