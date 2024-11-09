import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/model/login_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/auth_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/auth/otp_view.dart';
import 'package:uscitylink/views/auth/password_view.dart';

class LoginController extends GetxController {
  final __authService = AuthService();

  UserPreferenceController userPreferenceController =
      Get.put(UserPreferenceController());

  final emailController = TextEditingController().obs;
  final passwordController = TextEditingController().obs;

  final emailFoucsNode = FocusNode().obs;
  final passwordFoucsNode = FocusNode().obs;

  void loginApi(BuildContext context) {
    Map data = {"email": emailController.value.text};
    __authService.login(data).then((value) {
      if (value.status == true) {
        showAdaptiveActionSheet(
          context: context,
          actions: <BottomSheetAction>[
            BottomSheetAction(
              title: const Text(
                'Send OTP',
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
              ),
              onPressed: (_) {
                Navigator.of(context).pop();
                Get.to(() => OtpView(email: emailController.value.text));
              },
            ),
            BottomSheetAction(
              title: const Text(
                'Use Password',
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
              ),
              onPressed: (_) {
                Get.to(() => PasswordView(
                    email: emailController.value.text,
                    role: value.data.profiles?[0]?.role?.name as String));
                //Navigator.of(context).pop();
                // Pass email to Password view
              },
            ),
          ],
        );
      }
      // if (value != null) {
      //   print('Login successful: $value');
      // } else {
      //   print('Login failed');
      //   Utils.snackBar('Error', 'Login failed, please try again.');
      // }
    }).onError((error, stackTrace) {
      print('Error: $error');
      Utils.snackBar('Error', error.toString());
    });
  }

  void loginWithPassword(BuildContext context, String email, String role) {
    LoginWithPassword loginData = LoginWithPassword(
      email: email,
      role: role,
      password: passwordController.value.text,
    );

    __authService.loginWithPassword(loginData).then((value) {
      if (value.status == true) {
        if (value.data.access_token!.isNotEmpty) {
          userPreferenceController.storeToken(value.data).then((value) {
            Utils.toastMessage("Login Successfully");
            Get.offAllNamed(AppRoutes.driverDashboard);
          });
        }
      }
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
    });
  }

  void logOut() {
    userPreferenceController.removeStore().then((value) {
      Get.offAllNamed(AppRoutes.login);
    });
  }
}
