import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/file_picker_controller.dart';
import 'package:uscitylink/controller/image_picker_controller.dart';
import 'package:uscitylink/controller/staff/staffchat_controller.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/Colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/driver/views/chats/attachement_ui.dart';

class StaffMessageView extends StatefulWidget {
  final String channelId;
  final String userId;
  final String name;

  StaffMessageView({
    super.key,
    required this.channelId,
    required this.userId,
    required this.name,
  });

  @override
  _StaffMessageViewState createState() => _StaffMessageViewState();
}

class _StaffMessageViewState extends State<StaffMessageView> {
  late ScrollController _scrollController;

  StaffchatController _staffchatController = Get.put(StaffchatController());
  SocketService socketService = Get.find<SocketService>();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    _staffchatController.channelId.value = widget.channelId;
    _staffchatController.userId.value = widget.userId;
    _staffchatController.userName.value = widget.name;

    socketService.updateStaffActiveUserChat(widget.userId);
    _staffchatController.getChannelMembers(
        widget.userId, _staffchatController.currentPage.value);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Handle Scroll Listener
  void _scrollListener() {
    if (_staffchatController.loading.value) return;
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_staffchatController.currentPage.value <
          _staffchatController.totalPages.value) {
        _staffchatController.getChannelMembers(
          widget.userId,
          _staffchatController.currentPage.value + 1,
        );
      }
    }
  }

  // Function to send a message
  void _sendMessage() {
    if (_staffchatController.messageController.text.isNotEmpty) {
      socketService.updateStaffActiveUserChat(widget.userId);
      socketService.sendMessageToUser(
        widget.userId,
        _staffchatController.messageController.text,
        null,
      );
      _staffchatController.messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            socketService.updateStaffActiveUserChat("");
            _staffchatController.channelId.value = "";
            _staffchatController.userId.value = "";
            _staffchatController.userName.value = "";

            Get.back();
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
        backgroundColor: TColors.primaryStaff,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: Colors.white),
            ),
            Obx(() {
              return Text(
                _staffchatController.message.value.userProfile?.isOnline ??
                        false
                    ? "online"
                    : _staffchatController
                            .message.value.userProfile?.lastLogin ??
                        "",
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.white),
              );
            })
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(TDeviceUtils.getScreenHeight() * 0.01),
          child: Obx(() {
            if (_staffchatController.loading.value &&
                _staffchatController.message.value.messages?.length == 0) {
              return Center(
                child: CircularProgressIndicator(
                  color: TColors.primaryStaff,
                ),
              );
            }

            return Column(
              children: [
                if (_staffchatController.loading.value)
                  Column(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  ),
                Expanded(
                  child: Obx(() {
                    if (_staffchatController.message.value.messages?.isEmpty ??
                        true) {
                      return Center(
                        child: SizedBox(
                          height: 100,
                          width: 100,
                          child: InkWell(
                            onTap: () {},
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
                                Text(
                                  "Say Hi",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(color: Colors.grey.shade700),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount:
                          _staffchatController.message.value.messages?.length ??
                              0,
                      itemBuilder: (context, index) {
                        MessageModel message =
                            _staffchatController.message.value.messages![index];
                        return _buildChatMessage(message, context);
                      },
                    );
                  }),
                ),
                Obx(() {
                  return _staffchatController.typing.value
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
                              child: Text(
                                  _staffchatController.typingMessage.value),
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
                              _staffchatController.startTyping(widget.userId);
                            } else {
                              _staffchatController.stopTyping(widget.userId);
                            }
                          },
                          controller: _staffchatController.messageController,
                          decoration: InputDecoration(
                            hintText: "Type your message...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.attachment),
                              onPressed: () {
                                Get.bottomSheet(
                                  AttachmentBottomSheet(
                                    channelId: _staffchatController
                                        .message.value.userProfile!.channelId!,
                                    userId: widget.userId,
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
            );
          }),
        ),
      ),
    );
  }

  Widget _buildChatMessage(MessageModel message, BuildContext context) {
    bool hasImageUrl = message.url != null && message.url!.isNotEmpty;

    return Align(
      alignment: message.messageDirection == "S"
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: message.messageDirection == "S"
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              width: TDeviceUtils.getScreenWidth(context) * 0.5,
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: message.messageDirection == "S"
                    ? Colors.blue[200]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: message.messageDirection == "S"
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (hasImageUrl)
                    AttachementUi(fileUrl: "${Constant.aws}/${message.url}"),
                  const SizedBox(height: 5),
                  Text(
                    message.body!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 5),
                  Text(
                    message.messageDirection == "S"
                        ? "${Utils.formatUtcDateTime(message.messageTimestampUtc!)} ${message?.sender?.username}(staff)"
                        : "${message.sender?.username} ${Utils.formatUtcDateTime(message.messageTimestampUtc!)}",
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500),
                  ),
                  if (message.messageDirection == "S" &&
                      message.type == "truck_group")
                    Text("From Truck Group: ${message?.group?.name}",
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (message.messageDirection == "S")
              if (message.deliveryStatus == "sent")
                Icon(Icons.done, color: Colors.grey.shade500, size: 16)
              else
                Icon(Icons.done_all, color: Colors.blue.shade500, size: 16),
          ],
        ),
      ),
    );
  }
}

class AttachmentBottomSheet extends StatelessWidget {
  final String channelId;
  final String userId;
  final ImagePickerController imagePickerController =
      Get.put(ImagePickerController());

  final filePickerController = Get.put(FilePickerController());

  AttachmentBottomSheet(
      {super.key, required this.channelId, required this.userId});

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
                      channelId, "chat", "", "staff", userId);
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
                      channelId, "chat", "", "staff", userId);
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
                      channelId, "chat", "", "staff");
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
