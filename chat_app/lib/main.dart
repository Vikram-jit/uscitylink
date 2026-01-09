import 'package:chat_app/core/services/user_interaction_service.dart';
import 'package:chat_app/core/storage/storage_service.dart';
import 'package:chat_app/modules/driver_chat/screen/driver_chat.dart';
import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:chat_app/modules/not_found/not_found_view.dart';
import 'package:chat_app/routes/app_route_observer.dart';
import 'package:chat_app/routes/auth_middleware.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/bindings/initial_bindings.dart';
import 'core/theme/app_theme.dart' show AppTheme;
import 'modules/auth/login_view.dart';
import 'modules/home/home_view.dart';
import 'routes/app_routes.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  usePathUrlStrategy();

  runApp(
    GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => Get.find<UserInteractionService>().markInteracted(),
      onPanDown: (_) => Get.find<UserInteractionService>().markInteracted(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

      theme: AppTheme.main,

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
          binding: InitialBindings(),
        ),
        GetPage(
          name: AppRoutes.driverChat,
          page: () => DriverChat(),
          middlewares: [AuthMiddleware()],
          binding: InitialBindings(),
        ),
      ],

      // routingCallback: (Routing? routing) {
      //   if (routing != null && routing.current != routing.previous) {
      //     // Log route change
      //     print('Route changed from ${routing.previous} to ${routing.current}');
      //   }
      // },
      unknownRoute: GetPage(name: "/404", page: () => const NotFoundView()),
    );
  }
}
