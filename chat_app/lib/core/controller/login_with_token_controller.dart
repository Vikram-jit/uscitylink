import 'dart:convert';

import 'package:chat_app/core/services/socket_service.dart';
import 'package:chat_app/core/storage/storage_service.dart';
import 'package:chat_app/modules/auth/auth_model.dart';
import 'package:chat_app/modules/auth/auth_service.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:get/get.dart';

// ─────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────

class LoginWithTokenController extends GetxController {
  final isLoading = true.obs;
  final isSuccess = false.obs;
  final message = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Token is passed as a route argument: Get.toNamed('/login-with-token', arguments: 'YOUR_TOKEN')
    final token = Get.parameters['token'] ?? '';
    _handleToken(token);
    print(token);
  }

  Future<void> _handleToken(String token) async {
    if (token.isEmpty) {
      isLoading.value = false;
      isSuccess.value = false;
      message.value = 'Invalid or missing token.';
      return;
    }

    try {
      await StorageService.clear();

      final response = await AuthService().loginWithToken(token);

      if (response.status && response.data?.accessToken != null) {
        await StorageService.saveToken(response.data!.accessToken!);

        await StorageService.saveToken(response.data?.accessToken ?? "");
        await StorageService.saveUserData(response.data ?? AuthModel());

        SocketService().connect(response.data?.accessToken ?? "");
        Get.offAllNamed("/home");

        isSuccess.value = true;
        message.value = 'Login successful! Redirecting to dashboard…';

        await Future.delayed(const Duration(milliseconds: 800));
        Get.offAllNamed(AppRoutes.home);
      } else {
        isSuccess.value = false;
        message.value = response.message.isNotEmpty
            ? response.message
            : 'Login failed. Please try again.';
      }
    } catch (e) {
      print(e);
      isSuccess.value = false;
      message.value = 'An error occurred: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
