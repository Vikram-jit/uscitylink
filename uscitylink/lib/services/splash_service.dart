import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/auth_service.dart';
import 'package:uscitylink/services/fcm_service.dart';

class SplashService {
  UserPreferenceController userPreferenceController =
      UserPreferenceController();

  LoginController _loginController = Get.put(LoginController());

  AuthService _authService = AuthService();
  void isLogin() {
    userPreferenceController.getToken().then((value) async {
      if (value == null || value.isEmpty) {
        Get.offAllNamed(AppRoutes.login);
      } else {
        _loginController.checkRole();
      }
    });
  }
}
