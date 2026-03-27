import 'package:get/get.dart';

class GlobalLoaderController extends GetxController {
  final isLoading = false.obs;

  void show() => isLoading.value = true;

  void hide() => isLoading.value = false;
}
