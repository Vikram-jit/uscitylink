import 'package:chat_app/modules/home/models/channel_model.dart';
import 'package:chat_app/modules/home/models/overview_model.dart';
import 'package:chat_app/modules/home/services/channel_service.dart';
import 'package:get/get.dart';

class ChannelController extends GetxController {
  var currentTab = 0.obs; // 0 = Messages, 1 = Files, 2 = Pins
  var isLoading = false.obs;
  var errorText = "".obs;
  RxList<ChannelModel> channels = <ChannelModel>[].obs;
  @override
  void onInit() {
    super.onInit();
    getChannels();
  }

  Future<void> getChannels() async {
    try {
      isLoading.value = true;

      final res = await ChannelService().channels();

      if (res.status) {
        channels.value = res.data!;
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
