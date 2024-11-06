import 'package:get/get.dart';
import 'package:uscitylink/navigation_menu.dart';
import 'package:uscitylink/views/auth/login_view.dart';
import 'package:uscitylink/views/auth/otp_view.dart';
import 'package:uscitylink/views/auth/password_view.dart';
import 'package:uscitylink/views/driver/views/chats/message_ui.dart';
import 'package:uscitylink/views/driver/views/dashboard_view.dart';
import 'package:uscitylink/views/driver/views/settings/account_view.dart';
import 'package:uscitylink/views/driver/views/settings/change_password_view.dart';

class AppRoutes {
  static const String login = '/login';
  static const String passwordView = '/password';
  static const String otpView = '/otp';
  static const String navigationMenu = '/navigationMenu';

  static const String driverDashboard = '/driver/settings/driver_dashboard';

  // Driver routes with 'driver/' prefix
  static const String driverAccount = '/driver/settings/account';

  static const String driverChangePassword = '/driver/settings/change_password';

  static const String driverMessage = '/driver/chat/message';

  static final routes = [
    GetPage(name: login, page: () => const LoginView()),
    GetPage(name: navigationMenu, page: () => const NavigationMenu()),
    GetPage(name: passwordView, page: () => PasswordView(email: Get.arguments)),
    GetPage(name: otpView, page: () => OtpView(email: Get.arguments)),

    //Driver Routes

    GetPage(
      name: AppRoutes.driverDashboard,
      page: () => const DashboardView(),
    ),
    GetPage(
      name: AppRoutes.driverAccount,
      page: () => const AccountView(),
    ),

    GetPage(
      name: AppRoutes.driverChangePassword,
      page: () => const ChangePasswordView(),
    ),
    GetPage(
      name: AppRoutes.driverMessage,
      page: () => const Messageui(),
    ),
  ];
}
