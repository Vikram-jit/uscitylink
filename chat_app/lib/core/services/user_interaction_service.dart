import 'package:get/get.dart';

class UserInteractionService extends GetxService {
  final hasInteracted = false.obs;

  void markInteracted() {
    if (!hasInteracted.value) {
      hasInteracted.value = true;
      print('🔊 User interaction enabled');
    }
  }
}
