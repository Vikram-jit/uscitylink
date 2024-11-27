import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/auth_service.dart';
import 'package:uscitylink/services/fcm_service.dart';

class SplashService {
  UserPreferenceController userPreferenceController =
      UserPreferenceController();

  AuthService _authService = AuthService();
  void isLogin() {
    userPreferenceController.getToken().then((value) async {
      if (value == null || value.isEmpty) {
        Timer(
            const Duration(seconds: 1), () => Get.offAllNamed(AppRoutes.login));
      } else {
        final fcmService = Get.put(FCMService());
        String? token = fcmService.fcmToken.value;
        if (token != null && token.isNotEmpty) {
          await fcmService.updateDeviceToken(token);
        }

        Timer(const Duration(seconds: 1),
            () => Get.offAllNamed(AppRoutes.driverDashboard));
      }
    });
  }
}
