import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/file_picker_controller.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/controller/image_picker_controller.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/driver/views/chats/attachement_ui.dart';

class GroupMessageui extends StatefulWidget {
  final String channelId;
  final String groupId;
  final String name;
  const GroupMessageui(
      {required this.channelId,
      super.key,
      required this.name,
      required this.groupId});

  @override
  _GroupMessageuiState createState() => _GroupMessageuiState();
}

class _GroupMessageuiState extends State<GroupMessageui>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();

  late GroupController groupController;
  SocketService socketService = Get.put(SocketService());
  final ImagePickerController imagePickerController =
      Get.put(ImagePickerController());
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    // Initialize the MessageController and fetch messages for the given channelId
    groupController = Get.put(GroupController());
    groupController.getGroupMessages(widget.channelId,
        widget.groupId); // Fetch the messages for the given channelId

    // if (widget.channelId.isNotEmpty) {
    //   socketService.updateActiveChannel(widget.channelId);
    // }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print("App is in the background");
    } else if (state == AppLifecycleState.resumed) {
      if (!socketService.isConnected.value) {
        socketService.connectSocket();
      }
      if (!widget.channelId.isNotEmpty) {}
      groupController.getGroupMessages(widget.channelId, widget.groupId);
      print("App is in the foreground");
    }
  }

  @override
  void dispose() {
    //groupController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    // socketService.updateActiveChannel("");
    super.dispose();
  }

  // Function to send a new message
  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      socketService.sendGroupMessage(
          widget.groupId, widget.channelId, _controller.text, null);
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
              centerTitle: true,
              backgroundColor: TColors.primary,
              title: InkWell(
                onTap: () {
                  Get.toNamed(
                    AppRoutes.groupInfo,
                    arguments: {'groupId': widget.groupId},
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name, // Display the channel name
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
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
                  socketService.removeFromGroup(widget.groupId);
                  groupController.getUserGroups();
                  Get.back();
                },
              ),
              actions: [
                InkWell(
                    onTap: () {
                      imagePickerController.pickImageFromCamera(
                          widget.channelId, "group", widget.groupId);
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
                    groupController.getGroupMessages(
                        widget.channelId, widget.groupId);
                  },
                  child: Obx(() {
                    if (groupController.messages.isEmpty) {
                      return Center(
                          child: SizedBox(
                        height: 100,
                        width: 100,
                        child: InkWell(
                          onTap: () {
                            socketService.sendGroupMessage(
                                widget.groupId, widget.channelId, "Hi", null);
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
                      itemCount: groupController.messages.length,
                      itemBuilder: (context, index) {
                        return _buildChatMessage(
                            groupController.messages[index],
                            groupController.senderId.value);
                      },
                    );
                  }),
                ),
              ),
              // Obx(() {
              //   return groupController.typing.value
              //       ? Align(
              //           alignment: Alignment.centerLeft,
              //           child: Container(
              //             decoration: BoxDecoration(
              //               borderRadius: BorderRadius.circular(8),
              //               color: Colors.grey.shade300,
              //             ),
              //             width: TDeviceUtils.getScreenWidth(context) * 0.5,
              //             child: Padding(
              //               padding: const EdgeInsets.all(8.0),
              //               child: Obx(() {
              //                 return Text(
              //                     groupController.typingMessage.value);
              //               }),
              //             ),
              //           ),
              //         )
              //       : Container();
              // }),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Text Field for typing the message
                    Expanded(
                      child: TextField(
                        // onChanged: (text) {
                        //   if (text.isNotEmpty) {
                        //     messageController
                        //         .startTyping(widget.channelId); // Start typing
                        //   } else {
                        //     messageController.stopTyping(widget
                        //         .channelId); // Stop typing if text is empty
                        //   }
                        // },
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
                                  channelId: widget.channelId,
                                  groupId: widget.groupId,
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

  Widget _buildChatMessage(MessageModel message, String senderId) {
    bool hasImageUrl = message.url != null && message.url!.isNotEmpty;

    return Align(
      alignment: message.senderId == senderId
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: message.senderId == senderId
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              width: TDeviceUtils.getScreenWidth(context) * 0.5,
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: message.senderId == senderId
                    ? Colors.blue[200]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: message.senderId == senderId
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

                  Text(
                    Utils.formatUtcDateTime(message.messageTimestampUtc!),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (message.senderId == senderId)
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
            else
              Container(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Text(
                      message?.sender?.username ?? 'Unknown User',
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Badge(
                        backgroundColor: message?.sender?.isOnline ?? false
                            ? Colors.green
                            : Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}

class AttachmentBottomSheet extends StatelessWidget {
  final String channelId;
  final String groupId;
  final ImagePickerController imagePickerController =
      Get.put(ImagePickerController());

  final filePickerController = Get.put(FilePickerController());

  AttachmentBottomSheet(
      {super.key, required this.channelId, required this.groupId});

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
                      channelId, "group", groupId);
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
                      channelId, "group", groupId);
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
                      channelId, "group", groupId);
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
