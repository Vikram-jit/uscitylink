import 'package:chat_app/core/services/socket_service.dart';
import 'package:chat_app/core/storage/storage_service.dart';
import 'package:get/get.dart';

class AppInitController extends GetxController {
  @override
  void onReady() async {
    super.onReady();

    final token = await StorageService.getToken();

    if (token != null && token.isNotEmpty) {
      SocketService().connect(token);
      Get.offAllNamed('/home');
    } else {
      Get.offAllNamed('/login');
    }
  }
}
