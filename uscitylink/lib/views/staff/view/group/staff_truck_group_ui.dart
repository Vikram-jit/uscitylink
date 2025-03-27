import 'dart:async';

import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/audio_controller.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/file_picker_controller.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/controller/image_picker_controller.dart';
import 'package:uscitylink/controller/template_controller.dart';
import 'package:uscitylink/model/staff/truck_group_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/driver/views/chats/attachement_ui.dart';
import 'package:uscitylink/views/staff/widgets/template_dialog.dart';
import 'package:uscitylink/views/widgets/audio_record_widget.dart';

class StaffTruckGroupUi extends StatefulWidget {
  final String groupId;
  final int page;

  const StaffTruckGroupUi({super.key, required this.groupId, this.page = 1});

  @override
  _StaffTruckGroupUiState createState() => _StaffTruckGroupUiState();
}

class _StaffTruckGroupUiState extends State<StaffTruckGroupUi>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  late ScrollController _scrollController;
  ChannelController _channelController = Get.put(ChannelController());

  late GroupController groupController;
  SocketService socketService = Get.find<SocketService>();
  AudioController _audioController = Get.put(AudioController());
  final ImagePickerController imagePickerController =
      Get.put(ImagePickerController());
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      // Ensure the current page is less than the total pages
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (!groupController.isLoading.value &&
            groupController.currentPage.value <
                groupController.totalPages.value) {
          groupController.getTruckGroupMessages(
            widget.groupId,
            groupController.currentPage.value + 1,
          );
        }
      }
    });
    WidgetsBinding.instance.addObserver(this);
    // Initialize the MessageController and fetch messages for the given channelId
    groupController = Get.put(GroupController());
    groupController.getTruckGroupMessages(
        widget.groupId, groupController.currentPage.value);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print("App is in the background");
    } else if (state == AppLifecycleState.resumed) {
      if (!socketService.isConnected.value) {
        socketService.connectSocket();
      }
      Timer(Duration(seconds: 2), () {
        socketService.checkVersion();
      });
      if (!widget.groupId.isNotEmpty) {}
      groupController.getTruckGroupMessages(widget.groupId, widget.page);
      print("App is in the foreground");
    }
  }

  @override
  void dispose() {
    //groupController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    // socketService.updateActiveChannel("");
    Get.delete<AudioController>();
    super.dispose();
  }

  // Function to send a new message
  void _sendMessage() {
    String userProfileIds = groupController.group?.value?.groupMembers
            ?.where((member) {
              return member.userProfileId!.isNotEmpty &&
                  member.status == "active";
            }) // Force non-null assertion for userProfileId
            .map((member) => member.userProfileId)
            .join(',') ??
        ''; // Join and provide default empty string if null

    if (userProfileIds.isEmpty) {
      showAlert(context);
    } else {
      if (_controller.text.isNotEmpty) {
        if (socketService.isConnected.value) {
          socketService.sendMessageToTruck(
              userProfileIds,
              groupController.truckGroup.value!.group!.id!,
              _controller.text,
              groupController.templateurl.value);
        }
        _controller.clear();
        groupController.templateurl.value = "";
      }
    }
  }

  void showAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text('Please Add member before send message into group.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Column(
          children: [
            AppBar(
              backgroundColor: TColors.primaryStaff,
              title: InkWell(
                onTap: () {
                  Get.toNamed(
                    AppRoutes.staff_group_detail,
                    arguments: {'groupId': widget.groupId, 'type': 'truck'},
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      return Text(
                        "${groupController.truckGroup.value.group?.name}",
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: Colors.white),
                      );
                    }),
                    Obx(() {
                      String userNames = groupController
                              .truckGroup?.value?.members
                              ?.map((member) =>
                                  "${member.userProfile?.username} (${member.userProfile?.user?.driverNumber})" ??
                                  '') // Extract userProfileId
                              .where((id) =>
                                  id.isNotEmpty) // Filter out any empty values
                              .join(',') ??
                          "";
                      return Text(
                        "${userNames.isEmpty ? "No members" : userNames}",
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: Colors.white),
                      );
                    })
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
                  // socketService.removeFromGroup(widget.groupId);
                  // groupController.getUserGroups();
                  groupController.truckGroup.value = TruckGroupModel();
                  groupController.truckMessages.clear();
                  groupController.currentPage.value = 1;
                  groupController.totalPages.value = 1;

                  Get.back();
                },
              ),
              actions: [
                InkWell(
                    onTap: () {
                      // imagePickerController.pickImageFromCamera(
                      //     groupController.truckGroup.value.group. .channelId,
                      //     "group",
                      //     widget.groupId,
                      //     "driver_chat",
                      //     "");
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
                    // groupController.refreshMessages(
                    //     widget.channelId, widget.groupId);
                  },
                  child: Obx(() {
                    if (groupController.isLoading.value) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    //print(jsonEncode(groupController.truckMessages?.length));
                    if (groupController.truckMessages.isEmpty) {
                      return Center(
                          child: SizedBox(
                        height: 100,
                        width: 100,
                        child: InkWell(
                          onTap: () {
                            // socketService.addUserToGroup(
                            //     widget.channelId, widget.groupId);
                            // socketService.updateCountGroup(widget.channelId);
                            // socketService.sendGroupMessage(
                            //     widget.groupId, widget.channelId, "Hi", null);
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
                      itemCount: groupController.truckMessages.length,
                      itemBuilder: (context, index) {
                        // print(groupController.truckMessages.length);
                        // if (index == groupController.truckMessages.length - 1) {
                        //   if (groupController.isLoading.value) {
                        //     return Padding(
                        //       padding: const EdgeInsets.all(8.0),
                        //       child: Center(child: CircularProgressIndicator()),
                        //     );
                        //   } else {
                        //     return SizedBox.shrink();
                        //   }
                        // }
                        return _buildChatMessage(
                            groupController.truckMessages[index], "..");
                      },
                    );
                  }),
                ),
              ),
              if (groupController.templateurl.isNotEmpty)
                const SizedBox(width: 8),
              if (groupController.templateurl.isNotEmpty)
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: 100,
                    height: 100,
                    child: Image.network(
                      "${Constant.aws}/${groupController.templateurl.value}",
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
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(0.0),
                child: Obx(
                  () {
                    return Row(
                      children: [
                        // Text Field for typing the message
                        if (!_audioController.isRecording.value)
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: "Type your message...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons
                                          .attachment), // You can use any icon here
                                      onPressed: () {
                                        // Handle the icon press action
                                        Get.bottomSheet(
                                          AttachmentBottomSheet(
                                            channelId: "",
                                            groupId: widget.groupId,
                                            textEditingController: _controller,
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
                                                  : Icons.mic,
                                              size: 28),
                                          color:
                                              _audioController.isRecording.value
                                                  ? Colors.red
                                                  : Colors.blue,
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
                        if (_audioController.isRecording.value)
                          AudioRecordWidget(audioController: _audioController),
                        const SizedBox(width: 8),
                        // Plus button to send the message
                        GestureDetector(
                          onTap: () {
                            if (_audioController.isRecording.value) {
                              _audioController.sendAudio(
                                  groupController.group.value.group!
                                      .groupChannel!.channelId!,
                                  "media",
                                  "truck",
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatMessage(Messages message, String senderId) {
    bool hasImageUrl = message.url != null && message.url!.isNotEmpty;

    return Align(
      alignment: message.senderId != senderId
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: message.senderId != senderId
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              width: TDeviceUtils.getScreenWidth(context) * 0.7,
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: message.senderId != senderId
                    ? Colors.blue[200]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: message.senderId != senderId
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Display message body

                  // If there's an image URL, show the image with a loading indicator
                  if (hasImageUrl)
                    AttachementUi(
                      directionType: "S",
                      fileUrl: "${Constant.aws}/${message.url}",
                      thumbnail: "${Constant.aws}/${message.thumbnail}",
                    ),
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
  TextEditingController textEditingController;
  final ImagePickerController imagePickerController =
      Get.put(ImagePickerController());

  final filePickerController = Get.put(FilePickerController());
  GroupController _groupController = Get.find<GroupController>();
  TemplateController _templateController = Get.put(TemplateController());
  AttachmentBottomSheet(
      {super.key,
      required this.channelId,
      required this.groupId,
      required this.textEditingController});

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
                  TemplateDialog.showGroupTemplateBottomSheet(
                      context,
                      _templateController,
                      textEditingController,
                      _groupController);
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
                  imagePickerController.pickImageFromGallery(
                      channelId, "truck", groupId, "staff", "", "staff");
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
                      channelId, "truck", groupId, "staff", "");
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
                              "truck",
                              groupId,
                              "staff",
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
                              "truck",
                              groupId,
                              "staff",
                              "");
                          //Navigator.of(context).pop();
                          // Pass email to Password view
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
                  filePickerController.pickFileWithExtension(
                      channelId, "truck", groupId, "staff", "");
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
