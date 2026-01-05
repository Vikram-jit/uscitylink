import 'package:chat_app/core/services/socket_service.dart';
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String> getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token != null && token.isNotEmpty) {
      // 🔥 restore socket on refresh / reload
      SocketService().connect(token);
      return AppRoutes.home;
    }

    return AppRoutes.login;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getInitialRoute(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.main,

          initialRoute: snapshot.data!,
          getPages: [
            GetPage(name: AppRoutes.login, page: () => LoginView()),
            GetPage(
              name: AppRoutes.home,
              page: () => HomeView(),
              binding: InitialBindings(), // ✅ ONLY HERE
            ),
          ],

          unknownRoute: GetPage(name: "/404", page: () => const NotFoundView()),
        );
      },
    );
  }
}
