import 'package:chat_app/core/bindings/initial_bindings.dart';
import 'package:chat_app/core/services/socket_service.dart';
import 'package:chat_app/modules/auth/auth_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:chat_app/core/storage/storage_service.dart';
import 'package:socket_io_client/socket_io_client.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var errorText = "".obs;
  final authService = AuthService();
  final storageService = StorageService();
  final hidePassword = true.obs;
  TextEditingController emaiController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  Future<void> login() async {
    try {
      isLoading.value = true;

      final res = await authService.login(
        emaiController.text,
        passwordController.text,
      );

      if (res.status) {
        await StorageService.saveToken(res.data?.accessToken ?? "");

        // await StorageService.saveUser(res.data!.user!);
        // InitialBindings().dependencies();
        SocketService().connect(res.data?.accessToken ?? "");
        Get.offAllNamed("/home");
      } else {
        errorText.value = res.message;
      }
    } catch (e) {
      errorText.value = "Error: $e";
    } finally {
      isLoading.value = false;
    }
  }
}
