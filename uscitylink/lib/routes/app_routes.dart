import 'package:get/get.dart';
import 'package:uscitylink/navigation_menu.dart';
import 'package:uscitylink/views/auth/login_view.dart';
import 'package:uscitylink/views/auth/otp_view.dart';
import 'package:uscitylink/views/auth/password_view.dart';
import 'package:uscitylink/views/driver/views/group/group_info.dart';
import 'package:uscitylink/views/driver/views/group/group_media.dart';
import 'package:uscitylink/views/driver/views/group/group_message_ui.dart';
import 'package:uscitylink/views/driver/views/chats/message_ui.dart';
import 'package:uscitylink/views/driver/views/chats/profile_view.dart';
import 'package:uscitylink/views/driver/views/dashboard_view.dart';
import 'package:uscitylink/views/driver/views/group/member_search.dart';
import 'package:uscitylink/views/driver/views/settings/account_view.dart';
import 'package:uscitylink/views/driver/views/settings/change_password_view.dart';
import 'package:uscitylink/views/splash_view.dart';

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
  static const String driverGroupMessage = '/driver/chat/group_message';

  static const String splashView = '/';

  static const String profileView = '/profile';
  static const String membersView = '/group_members';
  static const String groupInfo = '/group_info';
  static const String groupMedia = '/group_media';

  static final routes = [
    GetPage(
        name: login,
        page: () => const LoginView(),
        transitionDuration: const Duration(milliseconds: 250),
        transition: Transition.leftToRightWithFade),
    GetPage(name: navigationMenu, page: () => const NavigationMenu()),
    GetPage(
        name: passwordView,
        page: () => PasswordView(email: Get.arguments, role: Get.arguments)),
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
        page: () {
          // Access arguments as a Map
          final args = Get.arguments as Map;
          final channelId = args['channelId'];
          final name = args['name'];

          return Messageui(
            channelId: channelId,
            name: name,
          );
        }),
    GetPage(
        name: AppRoutes.driverGroupMessage,
        page: () {
          // Access arguments as a Map
          final args = Get.arguments as Map;
          final channelId = args['channelId'];
          final groupId = args['groupId'];
          final name = args['name'];

          return GroupMessageui(
            channelId: channelId,
            groupId: groupId,
            name: name,
          );
        }),
    GetPage(
        name: AppRoutes.profileView,
        page: () {
          // Access arguments as a Map
          final args = Get.arguments as Map;
          final channelId = args['channelId'];

          return ProfileView(
            channelId: channelId,
          );
        }),
    GetPage(
        name: AppRoutes.groupMedia,
        page: () {
          // Access arguments as a Map
          final args = Get.arguments as Map;
          final channelId = args['groupId'];
          print(channelId);
          return GroupMedia(
            groupId: channelId,
          );
        }),
    GetPage(
        name: AppRoutes.membersView,
        page: () {
          // Access arguments as a Map
          final args = Get.arguments as Map;
          final groupId = args['groupId'];
          final groupMembers = args['groupMembers'];

          return MemberSearch(
            groupId: groupId,
            groupMembers: groupMembers,
          );
        }),
    GetPage(
        name: AppRoutes.groupInfo,
        page: () {
          // Access arguments as a Map
          final args = Get.arguments as Map;
          final groupId = args['groupId'];

          return GroupInfo(
            groupId: groupId,
          );
        }),
    GetPage(
        name: AppRoutes.splashView,
        page: () => const SplashView(),
        transitionDuration: const Duration(milliseconds: 250),
        transition: Transition.leftToRightWithFade),
  ];
}
