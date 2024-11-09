import 'package:get/get.dart';
import 'package:uscitylink/model/user_channel_model.dart';
import 'package:uscitylink/services/channel_service.dart';
import 'package:uscitylink/utils/utils.dart';

class ChannelController extends GetxController {
  var channels = <UserChannelModel>[].obs;

  final __channelService = ChannelService();
  var currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    currentIndex.listen((index) {
      // Call getUserChannels whenever the tab index changes
      if (index == 1) {
        getUserChannels(); // Fetch channels when tab 0 is selected
      }
    });
  }

  void getUserChannels() {
    __channelService.getUserChannels().then((response) {
      channels.value =
          response.data; // Update the observable list with the fetched channels
      print("Fetched channels: ${response.data}");
    }).onError((error, stackTrace) {
      print('Error: $error');
      Utils.snackBar('Error', error.toString());
    });
  }

  // Set the current index
  void setTabIndex(int index) {
    currentIndex.value = index;
  }
}
