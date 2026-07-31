import 'dart:async';

import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/audio_controller.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/file_picker_controller.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/controller/image_picker_controller.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/driver/views/chats/attachement_ui.dart';
import 'package:uscitylink/views/widgets/audio_record_widget.dart';

class GroupMessageui extends StatefulWidget {
  final String channelId;
  final String groupId;
  final String name;
  final int page;
  const GroupMessageui(
      {required this.channelId,
      super.key,
      required this.name,
      required this.groupId,
      this.page = 1});

  @override
  _GroupMessageuiState createState() => _GroupMessageuiState();
}

class _GroupMessageuiState extends State<GroupMessageui>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  late ScrollController _scrollController;
  ChannelController _channelController = Get.find<ChannelController>();

  late GroupController groupController;
  SocketService socketService = Get.find<SocketService>();
  AudioController _audioController = Get.put(AudioController());
  MessageController messageController = Get.put(MessageController());
  final ImagePickerController imagePickerController =
      Get.put(ImagePickerController());

  @override
  void initState() {
    if (socketService.isConnected.value) {
      socketService.addUserToGroup(widget.channelId, widget.groupId);
      socketService.updateCountGroup(widget.channelId);
    }

    super.initState();
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      // Ensure the current page is less than the total pages
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        // When scrolled to the bottom, load next page
        if (!groupController.isLoading.value &&
            groupController.currentPage.value <
                groupController.totalPages.value) {
          groupController.getGroupMessages(
            widget.channelId,
            widget.groupId,
            groupController.currentPage.value + 1,
          );
        }
      }
    });
    WidgetsBinding.instance.addObserver(this);
    // Initialize the MessageController and fetch messages for the given channelId
    groupController = Get.put(GroupController());
    groupController.getGroupMessages(
        widget.channelId,
        widget.groupId,
        groupController
            .currentPage.value); // Fetch the messages for the given channelId
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print("App is in the background");
    } else if (state == AppLifecycleState.resumed) {
      if (!socketService.isConnected.value) {
        socketService.connectSocket();
        Timer(Duration(seconds: 2), () {
          socketService.checkVersion();
        });
      }
      if (!widget.channelId.isNotEmpty) {}
      groupController.getGroupMessages(
          widget.channelId, widget.groupId, widget.page);
      print("App is in the foreground");
    }
  }

  @override
  void dispose() {
    //groupController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    messageController.dispose();
    // socketService.updateActiveChannel("");
    Get.delete<AudioController>();
    super.dispose();
  }

  // Function to send a new message
  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      socketService.addUserToGroup(widget.channelId, widget.groupId);
      socketService.updateCountGroup(widget.channelId);
      socketService.sendGroupMessage(
          widget.groupId, widget.channelId, _controller.text, null);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: AppBar(
              centerTitle: true,
              backgroundColor: TColors.navyHeader,
              elevation: 0,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ), // Back icon
                onPressed: () {
                  // Trigger the socket event when the back icon is clicked
                  socketService.removeFromGroup(widget.groupId);
                  groupController.getUserGroups();
                  groupController.messages.clear();
                  groupController.currentPage.value = 1;
                  groupController.totalPages.value = 1;
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
                          widget.channelId,
                          "group",
                          widget.groupId,
                          "driver_chat",
                          "");
                    },
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      color: Colors.white,
                    )),
                const SizedBox(
                  width: 20,
                )
              ],
            ),
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
                    groupController.refreshMessages(
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
                            socketService.addUserToGroup(
                                widget.channelId, widget.groupId);
                            socketService.updateCountGroup(widget.channelId);
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
                      controller: _scrollController,
                      reverse: true,
                      itemCount: groupController.messages.length,
                      itemBuilder: (context, index) {
                        if (index == groupController.messages.length - 1) {
                          if (groupController.isLoading.value) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          } else {
                            return SizedBox.shrink();
                          }
                        }
                        return _buildChatMessage(
                            groupController.messages[index],
                            groupController.senderId.value);
                      },
                    );
                  }),
                ),
              ),
              Obx(() {
                return groupController.typing.value
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          width: TDeviceUtils.getScreenWidth(context) * 0.5,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Obx(() {
                              return Text(
                                groupController.typingMessage.value,
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 13),
                              );
                            }),
                          ),
                        ),
                      )
                    : Container();
              }),
              Padding(
                padding: const EdgeInsets.all(0.0),
                child: Obx(
                  () {
                    return Row(
                      children: [
                        // Text Field for typing the message
                        if (!_audioController.isRecording.value)
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                              onChanged: (text) {
                                if (text.isNotEmpty) {
                                  groupController.startTyping(
                                      widget.groupId); // Start typing
                                } else {
                                  groupController.stopTyping(widget
                                      .groupId); // Stop typing if text is empty
                                }
                              },
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: "Type your message...",
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade500),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(26),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.attachment_rounded,
                                          color: Colors.grey.shade500),
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
                                    if (!_audioController.isRecording.value)
                                      Obx(
                                        () => IconButton(
                                          icon: Icon(
                                              _audioController.isRecording.value
                                                  ? Icons.stop
                                                  : Icons.mic_rounded,
                                              size: 24),
                                          color:
                                              _audioController.isRecording.value
                                                  ? const Color(0xFFEF4444)
                                                  : const Color(0xFF2E5BFF),
                                          onPressed: () {
                                            _audioController.isRecording.value
                                                ? _audioController
                                                    .stopRecording()
                                                : _audioController
                                                    .startRecording();
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              ),
                            ),
                          ),
                        if (_audioController.isRecording.value)
                          AudioRecordWidget(audioController: _audioController),
                        const SizedBox(width: 8),
                        // Plus button to send the message
                        GestureDetector(
                          onTap: () {
                            if (_audioController.isRecording.value) {
                              _audioController.sendAudio(
                                  widget.channelId,
                                  "media",
                                  "group",
                                  widget.groupId,
                                  "staff",
                                  "");
                            } else {
                              _sendMessage();
                            }
                          },
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: TColors.navyHeader,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: TColors.navyHeader.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
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
              width: TDeviceUtils.getScreenWidth(context) * 0.7,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: message.senderId == senderId
                    ? const Color(0xFFDCE9FF)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(
                      message.senderId == senderId ? 16 : 4),
                  bottomRight: Radius.circular(
                      message.senderId == senderId ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: message.senderId == senderId
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Display message body

                  // If there's an image URL, show the image with a loading indicator
                  if (hasImageUrl)
                    AttachementUi(
                      directionType: message.messageDirection!,
                      direction: message.userProfileId == message.sender,
                      url_upload_type: message.url_upload_type ?? "server",
                      fileUrl: "${Constant.aws}/${message.url}",
                      thumbnail: "${Constant.aws}/${message.thumbnail}",
                    ),
                  const SizedBox(height: 5),
                  SelectableText(
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: () {
                  imagePickerController.pickImageFromGallery(
                      channelId, "group", groupId, "driver_chat", "", "driver");
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _attachIcon(Icons.photo_rounded, const Color(0xFF2E5BFF)),
                    const SizedBox(height: 8),
                    Text("Photos",
                        style: Theme.of(context).textTheme.titleSmall)
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  imagePickerController.pickImageFromCamera(
                      channelId, "group", groupId, "driver_chat", "");
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _attachIcon(
                        Icons.add_a_photo_rounded, const Color(0xFF16A34A)),
                    const SizedBox(height: 8),
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
                              "group",
                              groupId,
                              "driver_chat",
                              "");
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
                              "group",
                              groupId,
                              "driver_chat",
                              "");
                        },
                      ),
                    ],
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _attachIcon(Icons.videocam_rounded, const Color(0xFF9333EA)),
                    const SizedBox(height: 8),
                    Text("Video", style: Theme.of(context).textTheme.titleSmall)
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  filePickerController.pickFileWithExtension(
                      channelId, "group", groupId, "driver_chat", "");
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _attachIcon(Icons.insert_drive_file_rounded,
                        const Color(0xFFF59E0B)),
                    const SizedBox(height: 8),
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

  Widget _attachIcon(IconData icon, Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}
