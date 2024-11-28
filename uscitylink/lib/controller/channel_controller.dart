import 'package:get/get.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/user_channel_model.dart';
import 'package:uscitylink/services/channel_service.dart';
import 'package:uscitylink/utils/utils.dart';

class ChannelController extends GetxController {
  var channels = <UserChannelModel>[].obs;
  var innerTabIndex = 0.obs;

  final __channelService = ChannelService();
  var currentIndex = 0.obs;

  GroupController groupController = Get.put(GroupController());

  @override
  void onInit() {
    super.onInit();
    currentIndex.listen((index) {
      if (index == 1) {
        getUserChannels();
      }
    });
    innerTabIndex.listen((index) {
      if (index == 0) {
        getUserChannels();
      }
      if (index == 1) {
        groupController.getUserGroups();
      }
    });
  }

  void getUserChannels() {
    __channelService.getUserChannels().then((response) {
      channels.value = response.data;
    }).onError((error, stackTrace) {
      Utils.snackBar('Error', error.toString());
    });
  }

  // Set the current index
  void setTabIndex(int index) {
    currentIndex.value = index;
  }

  void setInnerTabIndex(int index) {
    innerTabIndex.value = index;
  }

  // Update a channel with a new message
  void addNewMessage(dynamic messageData) {
    try {
      MessageModel message = MessageModel.fromJson(messageData);

      String channelId = message.channelId!;

      var channel = channels.firstWhere(
        (ch) => ch.channelId == channelId,
        orElse: () => UserChannelModel(id: channelId),
      );

      channel.updateWithNewMessage(message);

      channels.removeWhere((ch) => ch.channelId == channelId);
      channels.insert(0, channel);

      channels.refresh();
    } catch (e) {
      print("Error while adding new message: $e");
    }
  }

  void addNewChannel(dynamic data) {
    UserChannelModel userChannelModel = UserChannelModel.fromJson(data);

    channels.insert(0, userChannelModel);

    channels.refresh();
  }

  void updateCount(String channelId) {
    try {
      var channel = channels.firstWhere(
        (ch) => ch.channelId == channelId,
        orElse: () => UserChannelModel(id: channelId),
      );

      channel.recieve_message_count = 0;

      channels.refresh();
    } catch (e) {
      print("Error while adding new message: $e");
    }
  }

  void incrementCount(String channelId) {
    try {
      var channel = channels.firstWhere(
        (ch) => ch.channelId == channelId,
        orElse: () => UserChannelModel(id: channelId),
      );

      channel.recieve_message_count = (channel.recieve_message_count ?? 0) + 1;

      channels.refresh();
    } catch (e) {
      print("Error while adding new message: $e");
    }
  }
}
