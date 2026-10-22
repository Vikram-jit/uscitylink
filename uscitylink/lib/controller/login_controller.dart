import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:hive_ce/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uscitylink/controller/google_map_controller.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/controller/route_controller.dart';
import 'package:uscitylink/controller/station_controller.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/hive_boxes.dart';
import 'package:uscitylink/model/driver_model.dart';
import 'package:uscitylink/model/login_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/auth_service.dart';
import 'package:uscitylink/services/fcm_service.dart';
import 'package:uscitylink/services/network_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/hive_cleaner.dart';
import 'package:uscitylink/utils/roles.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/auth/otp_view.dart';
import 'package:uscitylink/views/auth/password_view.dart';
import 'package:uscitylink/views/auth/select_option.dart';
import 'package:uscitylink/views/update_view.dart';

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
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    currentIndex.listen((index) {
      print(index);
      if (index == 1) {
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
        final profiles = value.data.profiles ?? <Profiles>[];
        if (profiles.isEmpty) {
          Utils.snackBar('Error', 'No profile found for this account');
          return;
        }
        final email = value.data.email ?? "";
        final phone = value.data.phoneNumber ?? "";
        if (profiles.length > 1) {
          // One person with several logins (e.g. staff and driver): choose which one to sign in to
          showAdaptiveActionSheet(
            context: context,
            title: Text(
              "Select Profile",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            actions: <BottomSheetAction>[
              for (final profile in profiles)
                BottomSheetAction(
                  title: Text(
                    '${profile.role?.name?.toUpperCase() ?? ''}',
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.w600),
                  ),
                  onPressed: (sheetContext) {
                    // Close this sheet first, otherwise it stays open under the next screen
                    Navigator.of(sheetContext).pop();
                    _showLoginMethods(context, profile, email, phone);
                  },
                ),
            ],
          );
        } else {
          _showLoginMethods(context, profiles.first, email, phone);
        }
      }
    }).onError((error, stackTrace) {
      print('Error: $error');
      Utils.snackBar('Error', error.toString());
    });
  }

  // "Send OTP" / "Use Password" for the profile that was chosen
  void _showLoginMethods(
      BuildContext context, Profiles profile, String email, String phone) {
    final role = profile.role?.name ?? "";
    showAdaptiveActionSheet(
      context: context,
      title: _methodSheetTitle(profile),
      actions: <BottomSheetAction>[
        BottomSheetAction(
          title: const Text(
            'Send OTP',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
          ),
          onPressed: (sheetContext) {
            Navigator.of(sheetContext).pop();
            Get.to(() => SelectOption(
                name: profile.username ?? "",
                role: role,
                email: email,
                phone_number: phone));
          },
        ),
        BottomSheetAction(
          title: const Text(
            'Use Password',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
          ),
          onPressed: (sheetContext) {
            Navigator.of(sheetContext).pop();
            Get.to(() => PasswordView(
                email: emailController.value.text, role: role));
          },
        ),
      ],
    );
  }

  Widget? _methodSheetTitle(Profiles profile) {
    final role = profile.role?.name;
    if (role == null || role.isEmpty) return null;
    return Text(
      'Sign in as ${role[0].toUpperCase()}${role.substring(1)}',
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Future<PackageInfo> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo;
  }

  // Everything after a successful login (password or OTP): same for both, and the stored role and the
  // dashboard always come from the profile the server actually signed in
  Future<void> _completeLogin(
      LoginWithPasswordModel data, String chosenRole) async {
    await userPreferenceController.storeToken(data);
    final role = data.profiles?.role?.name ?? chosenRole;
    await userPreferenceController.storeRole(role);
    Utils.toastMessage("Login Successfully");
    if (!Get.isRegistered<MessageController>()) {
      Get.put(MessageController());
      print('📡 MessageController registered');
    }
    // ✅ Register NetworkService if not already
    if (!Get.isRegistered<NetworkService>()) {
      Get.put(NetworkService());
      print('📡 NetworkService registered');
    }

    final fcmService = Get.put(FCMService());
    String? token = fcmService.fcmToken.value;
    if (token.isNotEmpty) {
      await fcmService.updateDeviceToken(token);
    }
    await socketService.connectSocket();
    if (isStaffRole(role)) {
      Get.offAllNamed(AppRoutes.staff_dashboard);
    } else if (role == "security") {
      Get.offAllNamed(AppRoutes.securityDashboard);
    } else {
      Get.offAllNamed(AppRoutes.driverDashboard);
    }
  }

  void loginWithPassword(BuildContext context, String email, String role) {
    LoginWithPassword loginData = LoginWithPassword(
      email: email,
      role: role,
      password: passwordController.value.text,
    );

    __authService.loginWithPassword(loginData).then((value) async {
      if (value.status == true && (value.data.access_token ?? '').isNotEmpty) {
        await _completeLogin(value.data, role);
      }
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
    });
  }

  void loginWithOtp(BuildContext context, String email, String otp,
      [String role = '']) {
    LoginWithOTP loginData = LoginWithOTP(email: email, otp: otp, role: role);

    __authService.verifyOtp(loginData).then((value) async {
      if (value.status == true && (value.data.access_token ?? '').isNotEmpty) {
        await _completeLogin(value.data, role);
      }
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
    });
  }

  void sendOtp(BuildContext context, String email, String phone_number,
      bool isEmail, bool isPhoneNumber,
      [String role = '']) {
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
              role: role,
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
        await userPreferenceController.storeRole(value?.data?.role?.name ?? "");

        var buildInfo = await getAppVersion();

        if (buildInfo != null) {
          AppUpdateInfo appData = AppUpdateInfo(
              buildNumber: buildInfo.buildNumber,
              version: buildInfo.version,
              platform: Platform.operatingSystem);

          var result = await __authService.updateAppVersion(appData);

          if (result.data != "NewVersion") {
            //Get.offAll(() => UpdateView());
          } else {
            if (isStaffRole(value?.data?.role?.name)) {
              final fcmService = Get.put(FCMService());
              String? token = fcmService.fcmToken.value;
              if (token.isNotEmpty) {
                await fcmService.updateDeviceToken(token);
              }

              Timer(const Duration(seconds: 1),
                  () => Get.offAllNamed(AppRoutes.staff_dashboard));
            } else if (value?.data?.role?.name == "security") {
              final fcmService = Get.put(FCMService());
              String? token = fcmService.fcmToken.value;
              if (token.isNotEmpty) {
                await fcmService.updateDeviceToken(token);
              }

              Timer(const Duration(seconds: 1),
                  () => Get.offAllNamed(AppRoutes.securityDashboard));
            } else {
              final fcmService = Get.put(FCMService());
              String? token = fcmService.fcmToken.value;
              if (token.isNotEmpty) {
                await fcmService.updateDeviceToken(token);
              }

              Timer(const Duration(seconds: 1),
                  () => Get.offAllNamed(AppRoutes.driverDashboard));
            }
          }
        } else {
          if (isStaffRole(value?.data?.role?.name)) {
            final fcmService = Get.put(FCMService());
            String? token = fcmService.fcmToken.value;
            if (token.isNotEmpty) {
              await fcmService.updateDeviceToken(token);
            }

            Timer(const Duration(seconds: 1),
                () => Get.offAllNamed(AppRoutes.staff_dashboard));
          } else if (value?.data?.role?.name == "security") {
            final fcmService = Get.put(FCMService());
            String? token = fcmService.fcmToken.value;
            if (token.isNotEmpty) {
              await fcmService.updateDeviceToken(token);
            }

            Timer(const Duration(seconds: 1),
                () => Get.offAllNamed(AppRoutes.securityDashboard));
          } else {
            final fcmService = Get.put(FCMService());
            String? token = fcmService.fcmToken.value;
            if (token.isNotEmpty) {
              await fcmService.updateDeviceToken(token);
            }

            Timer(const Duration(seconds: 1),
                () => Get.offAllNamed(AppRoutes.driverDashboard));
          }
        }
      }
    }).onError((error, stackTrace) async {
      // print('Error: $error');

      if (error.toString() == "No Internet Connection") {
        String role = await userPreferenceController.getRole();
        if (role == "driver") {
          Timer(const Duration(seconds: 1),
              () => Get.offAllNamed(AppRoutes.driverDashboard));
        }
        if (isStaffRole(role)) {
          Timer(const Duration(seconds: 1),
              () => Get.offAllNamed(AppRoutes.staff_dashboard));
        }
        if (role == "security") {
          Timer(const Duration(seconds: 1),
              () => Get.offAllNamed(AppRoutes.securityDashboard));
        }
      }
      // Utils.snackBar('Error', error.toString());
      // Utils.snackBar('Error', error.toString());
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
    isLoading.value = true;
    __authService.getDriverProfile().then((value) async {
      if (value.status == true) {
        driverProfile.value = value.data;
        isLoading.value = false;
      }
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
      isLoading.value = false;
    });
  }

  Future<void> logOut() async {
    try {
      print('🚪 Starting logout process...');

      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // 1. Socket logout
      try {
        if (Get.isRegistered<SocketService>()) {
          Get.find<SocketService>().logout();
          print('✅ Socket disconnected');
        }
      } catch (e) {
        print('⚠️ Socket logout error: $e');
      }

      // 2. Dispose controllers FIRST so no async callbacks access Hive after close
      await _disposeAllControllers();

      // 3. Clear all Hive data now that no controllers hold box references
      await _forceClearAllHiveData();

      // 5. Auth service logout
      try {
        await __authService.logout();
        print('✅ Auth service logout successful');
      } catch (e) {
        print('ℹ️ Auth service logout info: $e');
      }
      // 4. Clear user preferences
      try {
        await userPreferenceController.removeStore();
        print('✅ User preferences cleared');
      } catch (e) {
        print('❌ Error clearing preferences: $e');
      }
      // 6. Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // 7. Navigate to login
      print('🚀 Navigating to login screen...');
      Get.offAllNamed(AppRoutes.login);
      print('✅ Logout complete');
    } catch (e) {
      print('❌ Fatal error during logout: $e');

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Force navigation even on error
      Get.offAllNamed(AppRoutes.login);
    }
  }

  Future<void> _forceClearAllHiveData() async {
    print('📦 FORCE CLEARING ALL HIVE DATA...');
    final failed = await clearAllHiveData(log: print);
    if (failed.isEmpty) {
      print('✅ ALL HIVE DATA FORCE CLEARED');
    } else {
      print('❌ Hive boxes not cleared: ${failed.join(', ')}');
    }
  }

  /// Deletes a controller by its registered *type* — every controller in
  /// this app is `Get.put()` without a tag, so the previous
  /// `Get.isRegistered(tag: name)` / `Get.delete(tag: name)` calls here
  /// never matched anything and silently disposed nothing. That let
  /// permanent controllers like `RouteController` survive logout holding
  /// `late Box<...>` fields pointing at boxes `_forceClearAllHiveData()` was
  /// about to close — the next Hive read on that stale controller then threw
  /// `HiveError: Box has already been closed.` `force: true` is required for
  /// `RouteController`, which is registered `permanent: true`.
  void _disposeByType<T>(String label) {
    try {
      if (Get.isRegistered<T>()) {
        Get.delete<T>(force: true);
        print('✅ Disposed: $label');
      }
    } catch (e) {
      print('⚠️ Error disposing $label: $e');
    }
  }

  /// Only the fuel-stations controllers get disposed here — they're the ones
  /// that actually hold the stale Hive box references from the bug above
  /// (`Get.put(RouteController(), permanent: true)` inside
  /// `FuelStationsView`, which re-creates them cleanly next time that
  /// feature is opened). `SocketService`, `NetworkService`, `HiveController`,
  /// `MessageController`, and `ChannelController` were in this list too when
  /// disposal was still a no-op; once the no-op was fixed, deleting them for
  /// real crashed the app immediately after logout — `SocketService` is
  /// `Get.put()` exactly once, in `main.dart` at boot, with no re-creation
  /// path, and `LoginController` (built the instant logout navigates to
  /// `/login`) does `Get.find<SocketService>()` unconditionally in its field
  /// initializer. The others follow the same "app-lifetime singleton with
  /// eager dependents" shape and were never actually implicated in the
  /// Hive-box bug, so they're left running across logout too.
  Future<void> _disposeAllControllers() async {
    print('🧹 Disposing all controllers...');

    _disposeByType<RouteController>('RouteController');
    _disposeByType<StationController>('StationController');
    _disposeByType<GoogleMapController>('GoogleMapController');
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
