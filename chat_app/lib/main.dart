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
  usePathUrlStrategy();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String> getInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    // 👇 If token exists -> go home, else -> go login
    return token == null || token.isEmpty ? AppRoutes.login : AppRoutes.home;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getInitial(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Center(child: CircularProgressIndicator()),
          );
        }
        final initialRoute = snapshot.data!;
        final bool needsBinding = initialRoute == AppRoutes.home;

        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.main,
          initialBinding: needsBinding ? InitialBindings() : null,
          initialRoute: initialRoute,
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

          // ❗ Unknown route
          unknownRoute: GetPage(name: "/404", page: () => const NotFoundView()),
        );
      },
    );
  }
}
