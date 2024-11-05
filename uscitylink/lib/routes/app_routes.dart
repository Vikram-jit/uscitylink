import 'package:get/get.dart';
import 'package:uscitylink/navigation_menu.dart';
import 'package:uscitylink/views/auth/login_view.dart';
import 'package:uscitylink/views/auth/otp_view.dart';
import 'package:uscitylink/views/auth/password_view.dart';
import 'package:uscitylink/views/driver/views/dashboard_view.dart';

class AppRoutes {
  static const String login = '/login';
  static const String passwordView = '/password';
  static const String otpView = '/otp';
  static const String navigationMenu = '/navigationMenu';

  static const String driverDashboard = '/driver_dashboard';

  static final routes = [
    GetPage(name: login, page: () => const LoginView()),
    GetPage(name: navigationMenu, page: () => const NavigationMenu()),
    GetPage(name: passwordView, page: () => PasswordView(email: Get.arguments)),
    GetPage(name: otpView, page: () => OtpView(email: Get.arguments)),

    //Driver Routes

    GetPage(
      name: AppRoutes.driverDashboard,
      page: () => const DashboardView(), // Your DriverDashboard widget
    ),
  ];
}
