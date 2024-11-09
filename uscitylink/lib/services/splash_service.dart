import 'dart:async';

import 'package:get/get.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';

class SplashService {
  UserPreferenceController userPreferenceController =
      UserPreferenceController();

  void isLogin() {
    userPreferenceController.getToken().then((value) {
      if (value == null || value.isEmpty) {
        Timer(
            const Duration(seconds: 1), () => Get.offAllNamed(AppRoutes.login));
      } else {
        Timer(const Duration(seconds: 1),
            () => Get.offAllNamed(AppRoutes.driverDashboard));
      }
    });
  }
}
