import 'package:chat_app/modules/broadcast_messages/Broadcast_controller.dart';
import 'package:get/get.dart';

class BroadcastBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BroadcastController>(
      () => BroadcastController(),
      fenix: true, // ✅ important
    );
  }
}
