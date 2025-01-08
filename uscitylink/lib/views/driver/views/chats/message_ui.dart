import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/file_picker_controller.dart';
import 'package:uscitylink/controller/image_picker_controller.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/driver/views/chats/attachement_ui.dart';

class Messageui extends StatefulWidget {
  final String channelId;
  final String name;
  const Messageui({required this.channelId, super.key, required this.name});

  @override
  _MessageuiState createState() => _MessageuiState();
}

class _MessageuiState extends State<Messageui> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  ChannelController _channelController = Get.find<ChannelController>();
  Timer? _channelUpdateTimer; // Timer for updating channelId

  late MessageController messageController;
  SocketService socketService = Get.find<SocketService>();
  final ImagePickerController imagePickerController =
      Get.put(ImagePickerController());
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    // Initialize the MessageController and fetch messages for the given channelId
    messageController = Get.put(MessageController());
    messageController.channelId.value = widget.channelId;
    messageController.name.value = widget.name;
    messageController.getChannelMessages(
        widget.channelId); // Fetch the messages for the given channelId

    if (widget.channelId.isNotEmpty) {
      socketService.updateActiveChannel(widget.channelId);
    }
    _startChannelUpdateTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state);
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      // App is in the background
      socketService.updateActiveChannel("");

      if (socketService.isConnected.value) {
        socketService.socket.disconnect();
      }
      print("App is in the background");
      // socketService.disconnect(); // Disconnect the socket when the app goes to background
    } else if (state == AppLifecycleState.resumed) {
      // App is in the foreground
      if (!socketService.isConnected.value) {
        socketService.connectSocket();
      }
      if (messageController.channelId.value.isNotEmpty) {
        socketService.updateActiveChannel(messageController.channelId.value);
      }
      messageController.getChannelMessages(messageController.channelId.value);
      _startChannelUpdateTimer();
      print("App is in the foreground");
      // socketService
      //     .connectSocket(); // Reconnect the socket when the app comes back to foreground
    }
  }

  void _startChannelUpdateTimer() {
    _channelUpdateTimer = Timer.periodic(Duration(seconds: 15), (_) {
      if (messageController.channelId.value.isNotEmpty) {
        socketService.updateActiveChannel(messageController
            .channelId.value); // Update the active channel every 15 seconds
      }
    });
  }

  @override
  void dispose() {
    print("dispose");
    _channelUpdateTimer?.cancel();
    // messageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    socketService.updateActiveChannel("");
    super.dispose();
  }

  // Function to send a new message
  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      socketService.updateActiveChannel(messageController.channelId.value);
      socketService.sendMessage(
          _controller.text, null, messageController.channelId.value);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Column(
          children: [
            AppBar(
              backgroundColor: TColors.primary,
              centerTitle: true,
              title: InkWell(
                onTap: () {
                  Get.toNamed(
                    AppRoutes.profileView,
                    arguments: {'channelId': messageController.channelId.value},
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      return Text(
                        messageController
                            .name.value, // Display the channel name
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: Colors.white),
                      );
                    })
                    // Text(
                    //   lastLogin, // Display the last login info
                    //   style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    // ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ), // Back icon
                onPressed: () {
                  // Trigger the socket event when the back icon is clicked
                  socketService.updateActiveChannel("");
                  if (_channelController.initialized) {
                    _channelController.getCount();
                  }
                  Get.back();
                },
              ),
              actions: [
                InkWell(
                    onTap: () {
                      imagePickerController.pickImageFromCamera(
                          messageController.channelId.value,
                          "chat",
                          "",
                          "driver_chat",
                          "");
                    },
                    child: const Icon(
                      Icons.add_a_photo,
                      color: Colors.white,
                    )),
                const SizedBox(
                  width: 20,
                )
              ],
            ),
            Container(
              height: 1.0,
              color: Colors.grey.shade300,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(TDeviceUtils.getAppBarHeight() * 0.4),
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    messageController
                        .getChannelMessages(messageController.channelId.value);
                  },
                  child: Obx(() {
                    if (messageController.messages.isEmpty) {
                      return Center(
                          child: SizedBox(
                        height: 100,
                        width: 100,
                        child: InkWell(
                          onTap: () {
                            socketService.sendMessage(
                                "Hi", null, messageController.channelId.value);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.waving_hand,
                                color: Colors.orange,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text("Say Hi",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(color: Colors.grey.shade700))
                            ],
                          ),
                        ),
                      ));
                    }
                    return ListView.builder(
                      reverse: true,
                      itemCount: messageController.messages.length,
                      itemBuilder: (context, index) {
                        return _buildChatMessage(
                            messageController.messages[index]);
                      },
                    );
                  }),
                ),
              ),
              Obx(() {
                return messageController.typing.value
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade300,
                          ),
                          width: TDeviceUtils.getScreenWidth(context) * 0.5,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Obx(() {
                              return Text(
                                  messageController.typingMessage.value);
                            }),
                          ),
                        ),
                      )
                    : Container();
              }),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Text Field for typing the message
                    Expanded(
                      child: TextField(
                        onChanged: (text) {
                          if (text.isNotEmpty) {
                            messageController
                                .startTyping(widget.channelId); // Start typing
                          } else {
                            messageController.stopTyping(widget
                                .channelId); // Stop typing if text is empty
                          }
                        },
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Type your message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          suffixIcon: IconButton(
                            icon: const Icon(
                                Icons.attachment), // You can use any icon here
                            onPressed: () {
                              // Handle the icon press action
                              Get.bottomSheet(
                                AttachmentBottomSheet(
                                  channelId: messageController.channelId.value,
                                ),
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Plus button to send the message
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatMessage(MessageModel message) {
    bool hasImageUrl = message.url != null && message.url!.isNotEmpty;

    return Align(
      alignment: message.messageDirection == "R"
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: message.messageDirection == "R"
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              width: TDeviceUtils.getScreenWidth(context) * 0.5,
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: message.messageDirection == "R"
                    ? Colors.blue[200]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: message.messageDirection == "R"
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Display message body

                  // If there's an image URL, show the image with a loading indicator
                  if (hasImageUrl)
                    AttachementUi(fileUrl: "${Constant.aws}/${message.url}"),
                  const SizedBox(height: 5),
                  Text(
                    message.body!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    message.messageDirection == "R"
                        ? "${Utils.formatUtcDateTime(message.messageTimestampUtc!)} You"
                        : "${message.sender?.username}(staff) ${Utils.formatUtcDateTime(message.messageTimestampUtc!)}  ",
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500),
                  ),
                  if (message.messageDirection == "S" &&
                      message.type == "truck_group")
                    Text("From Truck Group : ${message?.group?.name}",
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (message.messageDirection == "R")
              if (message.deliveryStatus == "sent")
                Icon(
                  Icons.done,
                  color: Colors.grey.shade500,
                  size: 16,
                )
              else
                Icon(
                  Icons.done_all,
                  color: Colors.blue.shade500,
                  size: 16,
                )
          ],
        ),
      ),
    );
  }
}

class AttachmentBottomSheet extends StatelessWidget {
  final String channelId;
  final ImagePickerController imagePickerController =
      Get.put(ImagePickerController());

  final filePickerController = Get.put(FilePickerController());

  AttachmentBottomSheet({super.key, required this.channelId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 150,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: () {
                  imagePickerController.pickImageFromGallery(
                      channelId, "chat", "", "driver_chat", "");
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.photo,
                      color: Colors.blue,
                      size: 34,
                    ),
                    Text("Photos",
                        style: Theme.of(context).textTheme.titleSmall)
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  imagePickerController.pickImageFromCamera(
                      channelId, "chat", "", "driver_chat", "");
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo,
                      color: Colors.black87,
                      size: 34,
                    ),
                    Text("Camera",
                        style: Theme.of(context).textTheme.titleSmall)
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  filePickerController.pickFileWithExtension(
                      channelId, "chat", "", "driver_chat");
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.edit_document,
                      color: Colors.black87,
                      size: 34,
                    ),
                    Text("Files", style: Theme.of(context).textTheme.titleSmall)
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
