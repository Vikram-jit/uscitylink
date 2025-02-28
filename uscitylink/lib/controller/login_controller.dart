import 'dart:async';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/model/driver_model.dart';
import 'package:uscitylink/model/login_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/auth_service.dart';
import 'package:uscitylink/services/fcm_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/auth/otp_view.dart';
import 'package:uscitylink/views/auth/password_view.dart';
import 'package:uscitylink/views/auth/select_option.dart';

class LoginController extends GetxController {
  final __authService = AuthService();

  UserPreferenceController userPreferenceController =
      Get.put(UserPreferenceController());

  SocketService socketService = Get.find<SocketService>();

  final emailController = TextEditingController().obs;
  final passwordController = TextEditingController().obs;

  final emailFoucsNode = FocusNode().obs;
  final passwordFoucsNode = FocusNode().obs;

  var userProfile = Profiles().obs; // A reactive Set of Profiles
  var currentIndex = 0.obs;

  var checkedEmailOtp = false.obs;
  var checkedPhoneNumberOtp = false.obs;

  var driverProfile = DriverModel().obs;

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
        if (value.data.profiles?.length == 2) {
          showAdaptiveActionSheet(
            context: context,
            title: Text(
              "Select Profile",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            actions: <BottomSheetAction>[
              if (value?.data?.profiles?[0] != null)
                BottomSheetAction(
                  title: Text(
                    '${value.data.profiles?[0].role?.name?.toUpperCase()}',
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.w600),
                  ),
                  onPressed: (_) {
                    showAdaptiveActionSheet(
                      context: context,
                      actions: <BottomSheetAction>[
                        BottomSheetAction(
                          title: const Text(
                            'Send OTP',
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600),
                          ),
                          onPressed: (_) {
                            Get.back();
                            Get.to((_) => SelectOption(
                                name: value.data?.profiles?[0].username ?? "",
                                role: value.data.profiles?[0].role?.name ?? "",
                                email: value.data.email ?? "",
                                phone_number: value.data.phoneNumber ?? ""));
                            // sendOtp(context, emailController.value.text);
                          },
                        ),
                        BottomSheetAction(
                          title: const Text(
                            'Use Password',
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600),
                          ),
                          onPressed: (_) {
                            Get.back();

                            Get.to(() => PasswordView(
                                email: emailController.value.text,
                                role: value.data.profiles?[0].role?.name
                                    as String));
                            //Navigator.of(context).pop();
                            // Pass email to Password view
                          },
                        ),
                      ],
                    );
                  },
                ),
              if (value?.data?.profiles?[1] != null)
                BottomSheetAction(
                  title: Text(
                    '${value.data.profiles?[1].role?.name?.toUpperCase()}',
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.w600),
                  ),
                  onPressed: (_) {
                    showAdaptiveActionSheet(
                      context: context,
                      actions: <BottomSheetAction>[
                        BottomSheetAction(
                          title: const Text(
                            'Send OTP',
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600),
                          ),
                          onPressed: (_) {
                            Get.back();

                            Get.to((_) => SelectOption(
                                name: value.data?.profiles?[1].username ?? "",
                                role: value.data.profiles?[1].role?.name ?? "",
                                email: value.data.email ?? "",
                                phone_number: value.data.phoneNumber ?? ""));
                            //sendOtp(context, emailController.value.text);
                          },
                        ),
                        BottomSheetAction(
                          title: const Text(
                            'Use Password',
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600),
                          ),
                          onPressed: (_) {
                            Get.back();

                            Get.to(() => PasswordView(
                                email: emailController.value.text,
                                role: value.data.profiles?[1].role?.name
                                    as String));
                            //Navigator.of(context).pop();
                            // Pass email to Password view
                          },
                        ),
                      ],
                    );
                  },
                ),
            ],
          );
        } else {
          showAdaptiveActionSheet(
            context: context,
            actions: <BottomSheetAction>[
              BottomSheetAction(
                title: const Text(
                  'Send OTP',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.w600),
                ),
                onPressed: (_) {
                  Get.back();

                  Get.to(() => SelectOption(
                      name: value.data?.profiles?[0].username ?? "",
                      role: value.data.profiles?[0].role?.name ?? "",
                      email: value.data.email ?? "",
                      phone_number: value.data.phoneNumber ?? ""));
                  // sendOtp(context, emailController.value.text);
                },
              ),
              BottomSheetAction(
                title: const Text(
                  'Use Password',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.w600),
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

  Future<PackageInfo> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo;
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
          userPreferenceController
              .storeToken(value.data)
              .then((response) async {
            Utils.toastMessage("Login Successfully");
            final fcmService = Get.put(FCMService());
            String? token = fcmService.fcmToken.value;
            if (token != null && token.isNotEmpty) {
              await fcmService.updateDeviceToken(token);
            }
            await socketService.connectSocket();
            if (value.data.profiles?.role?.name == "staff") {
              Get.offAllNamed(AppRoutes.staff_dashboard);
            } else {
              Get.offAllNamed(AppRoutes.driverDashboard);
            }
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

  void sendOtp(BuildContext context, String email, String phone_number,
      bool isEmail, bool isPhoneNumber) {
    OTP OTPData = OTP(
      isEmail: isEmail,
      isPhoneNumber: isPhoneNumber,
      email: email,
      phone_number: phone_number,
    );

    __authService.getOtp(OTPData).then((value) {
      if (value.status == true) {
        Utils.toastMessage("Otp Send Successfully");

        Get.to(() => OtpView(
              email: email,
              phone_number: phone_number,
              isEmail: isEmail,
              isPhoneNumber: isPhoneNumber,
            ));
      }
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
    });
  }

  void resendOtp(BuildContext context, String email, String phone_number,
      bool isEmail, bool isPhoneNumber) {
    OTP OTPData = OTP(
      isEmail: isEmail,
      isPhoneNumber: isPhoneNumber,
      email: email,
      phone_number: phone_number,
    );

    __authService.resendOtp(OTPData).then((value) {
      if (value.status == true) {
        Utils.toastMessage("Otp Resent Successfully");
      }
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
    });
  }

  void checkRole() {
    __authService.getProfile().then((value) async {
      if (value.status == true) {
        var buildInfo = await getAppVersion();

        if (buildInfo != null) {
          AppUpdateInfo appData = AppUpdateInfo(
              buildNumber: buildInfo.buildNumber, version: buildInfo.version);
          if (value.data.buildNumber == null && value.data.version == null) {
            await __authService.updateAppVersion(appData);
          }
          if (value.data.buildNumber != buildInfo.buildNumber) {
            await __authService.updateAppVersion(appData);
          }
          if (value.data.version != buildInfo.version) {
            await __authService.updateAppVersion(appData);
          }
        }
        // print(buildInfo.buildNumber);
        // print(buildInfo.version);
        if (value?.data?.role?.name == "staff") {
          final fcmService = Get.put(FCMService());
          String? token = fcmService.fcmToken.value;
          if (token != null && token.isNotEmpty) {
            await fcmService.updateDeviceToken(token);
          }

          Timer(const Duration(seconds: 1),
              () => Get.offAllNamed(AppRoutes.staff_dashboard));
        } else {
          final fcmService = Get.put(FCMService());
          String? token = fcmService.fcmToken.value;
          if (token != null && token.isNotEmpty) {
            await fcmService.updateDeviceToken(token);
          }

          Timer(const Duration(seconds: 1),
              () => Get.offAllNamed(AppRoutes.driverDashboard));
        }
      }
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
    });
  }

  void getProfile() {
    __authService.getProfile().then((value) async {
      if (value.status == true) {
        userProfile.value = value.data;
      }
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
    });
  }

  void getDriverProfile() {
    __authService.getDriverProfile().then((value) async {
      if (value.status == true) {
        driverProfile.value = value.data;
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
