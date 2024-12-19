import 'dart:convert';

import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/model/login_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/auth_service.dart';
import 'package:uscitylink/services/fcm_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/auth/otp_view.dart';
import 'package:uscitylink/views/auth/password_view.dart';

class LoginController extends GetxController {
  final __authService = AuthService();

  UserPreferenceController userPreferenceController =
      Get.put(UserPreferenceController());

  SocketService socketService = Get.find<SocketService>();

  final emailController = TextEditingController().obs;
  final passwordController = TextEditingController().obs;

  final emailFoucsNode = FocusNode().obs;
  final passwordFoucsNode = FocusNode().obs;

  var userProfile = <Profiles>{}.obs; // A reactive Set of Profiles
  var currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    currentIndex.listen((index) {
      if (index == 3) {
        getProfile();
      }
    });
  }

  void setTabIndex(int index) {
    currentIndex.value = index;
  }

  void loginApi(BuildContext context) {
    Map data = {"email": emailController.value.text};
    __authService.login(data).then((value) {
      if (value.status == true) {
        if (value.data.profiles != null && value.data.profiles!.isNotEmpty) {
          if (value.data.profiles![0].role?.name != "driver") {
            throw Exception('Error: Invalid credentials');
          }
        } else {
          throw Exception('Error: No profiles found');
        }
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
                sendOtp(context, emailController.value.text);
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
                    role: value.data.profiles?[0].role?.name as String));
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
          userPreferenceController.storeToken(value.data).then((value) async {
            Utils.toastMessage("Login Successfully");
            final fcmService = Get.put(FCMService());
            String? token = fcmService.fcmToken.value;
            if (token != null && token.isNotEmpty) {
              await fcmService.updateDeviceToken(token);
            }
            await socketService.connectSocket();
            Get.offAllNamed(AppRoutes.driverDashboard);
          });
        }
      }
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
    });
  }

  void loginWithOtp(BuildContext context, String email, String otp) {
    LoginWithOTP loginData = LoginWithOTP(email: email, otp: otp);

    __authService.verifyOtp(loginData).then((value) {
      if (value.status == true) {
        if (value.data.access_token!.isNotEmpty) {
          userPreferenceController.storeToken(value.data).then((value) async {
            Utils.toastMessage("Login Successfully");
            final fcmService = Get.put(FCMService());
            String? token = fcmService.fcmToken.value;
            if (token != null && token.isNotEmpty) {
              await fcmService.updateDeviceToken(token);
            }
            await socketService.connectSocket();
            Get.offAllNamed(AppRoutes.driverDashboard);
          });
        }
      }
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
    });
  }

  void sendOtp(BuildContext context, String email) {
    OTP OTPData = OTP(
      email: email,
    );

    __authService.getOtp(OTPData).then((value) {
      if (value.status == true) {
        Utils.toastMessage("Otp Send Successfully");
        Navigator.of(context).pop();
        Get.to(() => OtpView(email: emailController.value.text));
      }
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
    });
  }

  void resendOtp(BuildContext context, String email) {
    OTP OTPData = OTP(
      email: email,
    );

    __authService.resendOtp(OTPData).then((value) {
      if (value.status == true) {
        Utils.toastMessage("Otp Resent Successfully");
      }
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
    });
  }

  void getProfile() {
    __authService.getProfile().then((value) {
      if (value.status == true) {
        userProfile.value = {
          Profiles(
            id: value.data.id,
            username: value.data.username,
          )
        };
      }
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
    });
  }

  void logOut() async {
    Get.find<SocketService>().logout();
    __authService.logout().then((value) {
      // if (value.status == true) {
      //   Utils.toastMessage("Logout Successfully");

      //   Get.offAllNamed(AppRoutes.login);
      // }
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
    });
    userPreferenceController.removeStore().then((value) {
      Get.offAllNamed(AppRoutes.login);
    });
  }

  void changePassword(BuildContext context, String old_password,
      String new_password, String confirm_password) {
    __authService.changePassword({
      "old_password": old_password,
      "new_password": new_password,
      "confirm_password": confirm_password
    }).then((value) {
      if (value.status == true) {
        Utils.toastMessage(value.message);
        Navigator.of(context).pop();
      }
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
    });
  }
}
