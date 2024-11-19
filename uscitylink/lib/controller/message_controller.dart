import 'package:get/get.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/user_channel_model.dart';
import 'package:uscitylink/services/channel_service.dart';
import 'package:uscitylink/services/message_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/utils.dart';

class MessageController extends GetxController {
  var messages = <MessageModel>[].obs;

  final __messageService = MessageService();
  var currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();

    Map args = Get.arguments as Map? ?? {};

    String channelId = args['channelId'] ?? '';

    if (channelId.isNotEmpty) {
      getChannelMessages(channelId);
    } else {
      print("Error: channelId is empty or invalid.");
    }
  }

  void getChannelMessages(String channelId) {
    __messageService.getChannelMessages(channelId).then((response) {
      messages.value = response.data;
    }).onError((error, stackTrace) {
      print('Error: $error');
      Utils.snackBar('Error', error.toString());
    });
  }

  void onNewMessage(dynamic data) {
    print(data);
    // Assuming the incoming message is a Map or JSON object that can be parsed to MessageModel
    MessageModel newMessage =
        MessageModel.fromJson(data); // Convert the data to MessageModel

    messages.insert(0, newMessage); // Append the new message to the list
    messages.refresh();
  }
}
