import 'dart:async';

import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/file_picker_controller.dart';
import 'package:uscitylink/controller/image_picker_controller.dart';
import 'package:uscitylink/controller/staff/staffchat_controller.dart';
import 'package:uscitylink/controller/template_controller.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/staff/user_message_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/Colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/driver/views/chats/attachement_ui.dart';
import 'package:uscitylink/views/staff/widgets/template_dialog.dart';

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

class _StaffMessageViewState extends State<StaffMessageView>
    with WidgetsBindingObserver {
  late ScrollController _scrollController;

  StaffchatController _staffchatController = Get.put(StaffchatController());
  SocketService socketService = Get.find<SocketService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    _staffchatController.channelId.value = widget.channelId;
    _staffchatController.userId.value = widget.userId;
    _staffchatController.userName.value = widget.name;

    socketService.updateStaffActiveUserChat(_staffchatController.userId.value);
    _staffchatController.getChannelMembers(
        _staffchatController.userId.value,
        _staffchatController.currentPage.value,
        _staffchatController.channelId.value);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      // App is in the background
      socketService.updateStaffActiveUserChat("");
      _staffchatController.currentPage.value = 1;
      _staffchatController.totalPages.value = 1;
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
      Timer(Duration(seconds: 2), () {
        socketService.checkVersion();
      });
      socketService
          .updateStaffActiveUserChat(_staffchatController.userId.value);

      _staffchatController.getChannelMembers(_staffchatController.userId.value,
          1, _staffchatController.channelId.value);

      print("App is in the foreground");
      // socketService
      //     .connectSocket(); // Reconnect the socket when the app comes back to foreground
    }
  }

  @override
  void dispose() {
    socketService.updateStaffActiveUserChat('');
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _staffchatController.currentPage.value = 1;
    _staffchatController.totalPages.value = 1;
    WidgetsBinding.instance.removeObserver(this);
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
            _staffchatController.userId.value,
            _staffchatController.currentPage.value + 1,
            _staffchatController.channelId.value);
      }
    }
  }

  // Function to send a message
  void _sendMessage() {
    if (_staffchatController.messageController.text.isNotEmpty) {
      socketService
          .updateStaffActiveUserChat(_staffchatController.userId.value);
      socketService.sendMessageToUser(
        _staffchatController.userId.value,
        _staffchatController.messageController.text,
        _staffchatController.templateUrl.value,
      );
      _staffchatController.templateUrl.value = "";
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
            _staffchatController.currentPage.value = 1;
            _staffchatController.totalPages.value = 1;
            _staffchatController.message.value = UserMessageModel();
            Get.back();
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
        backgroundColor: TColors.primaryStaff,
        title: InkWell(
          onTap: () {
            Get.toNamed(
              AppRoutes.profileView,
              arguments: {
                'channelId': _staffchatController.userId.value,
                'type': "staff"
              },
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                return Text(
                  _staffchatController.userName.value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: Colors.white),
                );
              }),
              Obx(() {
                return Text(
                  _staffchatController.message.value.userProfile?.isOnline ??
                          false
                      ? "online"
                      : Utils.formatUtcDateTime(_staffchatController
                              .message.value.userProfile?.lastLogin) ??
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
                        return _buildChatMessage(message, context,
                            _staffchatController.truckNumbers.value);
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
                if (_staffchatController.templateUrl.isNotEmpty)
                  const SizedBox(width: 8),
                if (_staffchatController.templateUrl.isNotEmpty)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 100,
                      height: 100,
                      child: Image.network(
                        "${Constant.aws}/${_staffchatController.templateUrl.value}",
                        fit: BoxFit.contain,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            // Image has finished loading
                            return child;
                          } else {
                            // Show a loading indicator while the image is loading
                            return Center(
                              child: CircularProgressIndicator(
                                color: TColors.primaryStaff,
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Text Field for typing the message
                      Expanded(
                        child: TextField(
                          onChanged: (text) {
                            if (text.isNotEmpty) {
                              _staffchatController.startTyping(
                                  _staffchatController.userId.value);
                            } else {
                              _staffchatController.stopTyping(
                                  _staffchatController.userId.value);
                            }
                          },
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
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
                                    channelId:
                                        _staffchatController.channelId.value,
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

  Widget _buildChatMessage(
      MessageModel message, BuildContext context, String trucknumbers) {
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
                    AttachementUi(
                      fileUrl: "${Constant.aws}/${message.url}",
                      thumbnail: "${Constant.aws}/${message.thumbnail}",
                    ),
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
                  if (message.messageDirection == "R" &&
                      trucknumbers.isNotEmpty)
                    Text("Assigned trucks:- ${trucknumbers}",
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
  final templateController = Get.put(TemplateController());
  StaffchatController _staffchatController = Get.find<StaffchatController>();
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
                  TemplateDialog.showDriverBottomSheet(
                      context, templateController, _staffchatController);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.backup_table,
                      color: Colors.black,
                      size: 34,
                    ),
                    Text("Templates",
                        style: Theme.of(context).textTheme.titleSmall)
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  imagePickerController.pickImageFromGallery(channelId, "chat",
                      "", "staff", _staffchatController.userId.value);
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
                  imagePickerController.pickImageFromCamera(channelId, "chat",
                      "", "staff", _staffchatController.userId.value);
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
                  showAdaptiveActionSheet(
                    context: context,
                    actions: <BottomSheetAction>[
                      BottomSheetAction(
                        title: const Text(
                          'Camera',
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.w600),
                        ),
                        onPressed: (_) {
                          Get.back();
                          imagePickerController.recordVedioFromCamera(
                              ImageSource.camera,
                              channelId,
                              "chat",
                              "",
                              "staff",
                              _staffchatController.userId.value);
                          // sendOtp(context, emailController.value.text);
                        },
                      ),
                      BottomSheetAction(
                        title: const Text(
                          'Gallery',
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.w600),
                        ),
                        onPressed: (_) {
                          Get.back();

                          imagePickerController.recordVedioFromCamera(
                              ImageSource.gallery,
                              channelId,
                              "chat",
                              "",
                              "staff",
                              _staffchatController.userId.value);
                        },
                      ),
                    ],
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.video_camera_back,
                      color: Colors.black87,
                      size: 34,
                    ),
                    Text("Video", style: Theme.of(context).textTheme.titleSmall)
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  filePickerController.pickFileWithExtension(channelId, "chat",
                      "", "staff", _staffchatController.userId.value);
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
