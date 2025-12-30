import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/modules/not_found/not_found_view.dart';
import 'package:chat_app/routes/auth_middleware.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/bindings/initial_bindings.dart';
import 'core/theme/app_theme.dart' show AppTheme;
import 'modules/auth/login_view.dart';
import 'modules/home/home_view.dart';
import 'routes/app_routes.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  InitialBindings().dependencies();
  usePathUrlStrategy(); // 👈 removes # from web URLs
  Get.put(MessageController());

  Get.put(HomeController());
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");

  final String startRoute = token == null ? AppRoutes.login : AppRoutes.home;

  runApp(MyApp(startRoute: startRoute));
}

class MyApp extends StatelessWidget {
  final String startRoute;
  const MyApp({super.key, required this.startRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.main,
      initialRoute: startRoute, // 👈 dynamic route based on login
      getPages: [
        GetPage(
          name: AppRoutes.login,
          page: () => LoginView(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: AppRoutes.home,
          page: () => HomeView(),
          middlewares: [AuthMiddleware()],
        ),
      ],
      unknownRoute: GetPage(
        name: "/404",
        page: () => const NotFoundView(),
        transition: Transition.fadeIn,
      ),
    );
  }
}
