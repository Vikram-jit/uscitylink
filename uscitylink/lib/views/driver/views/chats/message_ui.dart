import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
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
  DashboardController _dashboardController = Get.find<DashboardController>();
  late MessageController messageController;
  final FocusNode _focusNode = FocusNode();
  SocketService socketService = Get.find<SocketService>();
  final ImagePickerController imagePickerController =
      Get.put(ImagePickerController());

  final ScrollController _scrollController = ScrollController();

  String pinMessage = "0";

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
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      // App is in the background
      socketService.updateActiveChannel("");

      if (socketService.isConnected.value) {
        socketService.socket.disconnect();
      }
      print("App is in the background");
    } else if (state == AppLifecycleState.resumed) {
      // App is in the foreground
      if (!socketService.isConnected.value) {
        socketService.connectSocket();
        Timer(Duration(seconds: 2), () {
          socketService.checkVersion();
        });
      }
      if (messageController.channelId.value.isNotEmpty) {
        socketService.updateActiveChannel(messageController.channelId.value);
      }
      messageController.getChannelMessages(messageController.channelId.value);
      _startChannelUpdateTimer();
      print("App is in the foreground");
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
    _channelUpdateTimer?.cancel();
    // messageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    socketService.updateActiveChannel("");
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Because we have reverse: true, the bottom is at the minScrollExtent.
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Function to send a new message
  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      socketService.updateActiveChannel(messageController.channelId.value);
      socketService.sendMessage(
          _controller.text,
          null,
          messageController.channelId.value,
          null,
          messageController.selectedRplyMessage.value.id);
      if (messageController.selectedRplyMessage.value.id != null) {
        messageController.selectedRplyMessage.value = MessageModel();
      }
      _scrollToBottom();
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
              centerTitle: false,
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
                  _dashboardController.getDashboard();
                  Get.back();
                },
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                      width: 10,
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          pinMessage = pinMessage == "0" ? "1" : "0";
                        });
                        messageController.getChannelMessages(
                            widget.channelId, pinMessage);
                      },
                      child: Icon(
                        Icons.push_pin,
                        color: pinMessage == "1" ? Colors.amber : Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  width: 20,
                ),
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
                      controller: _scrollController,
                      reverse: true,
                      itemCount: messageController.messages.length,
                      itemBuilder: (context, index) {
                        return _buildChatMessage(
                            messageController.messages[index],
                            messageController,
                            _focusNode,
                            socketService);
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
              Obx(
                () {
                  // ignore: unnecessary_null_comparison
                  return messageController.selectedRplyMessage.value.id != null
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border(
                                  left: BorderSide(
                                      color: messageController
                                                  .selectedRplyMessage
                                                  .value
                                                  .messageDirection ==
                                              "R"
                                          ? Colors.blue
                                          : Colors.amber,
                                      width: 4)),
                              color: Colors.grey.shade200,
                            ),
                            width: TDeviceUtils.getScreenWidth(context) * 1,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 8.0, right: 8.0, left: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Obx(() {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          textAlign: TextAlign.start,
                                          messageController.selectedRplyMessage
                                                      .value.messageDirection ==
                                                  "R"
                                              ? "You"
                                              : "${messageController.selectedRplyMessage.value.sender?.username}(staff)",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            messageController
                                                .selectedRplyMessage
                                                .value = MessageModel();
                                            FocusScope.of(context).unfocus();
                                          },
                                          child: Container(
                                            height: 20,
                                            width: 20,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: messageController
                                                              .selectedRplyMessage
                                                              .value
                                                              .messageDirection ==
                                                          "R"
                                                      ? Colors.blue
                                                      : Colors.amber),
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                            ),
                                            child: Center(
                                                child: Icon(
                                              Icons.close_rounded,
                                              size: 12,
                                              color: messageController
                                                          .selectedRplyMessage
                                                          .value
                                                          .messageDirection ==
                                                      "R"
                                                  ? Colors.blue
                                                  : Colors.amber,
                                            )),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                  if (messageController
                                              .selectedRplyMessage.value.url !=
                                          null &&
                                      messageController.selectedRplyMessage
                                          .value.url!.isNotEmpty)
                                    AttachementUi(
                                      fileUrl:
                                          "${Constant.aws}/${messageController.selectedRplyMessage.value.url}",
                                      thumbnail:
                                          "${Constant.aws}/${messageController.selectedRplyMessage.value.thumbnail}",
                                    ),
                                  const SizedBox(height: 1),
                                  Text(
                                    messageController
                                        .selectedRplyMessage.value.body!,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SizedBox();
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Text Field for typing the message
                        Expanded(
                          child: TextField(
                            onChanged: (text) {
                              if (text.isNotEmpty) {
                                messageController.startTyping(
                                    widget.channelId); // Start typing
                              } else {
                                messageController.stopTyping(widget
                                    .channelId); // Stop typing if text is empty
                              }
                            },
                            controller: _controller,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: "Type your message...",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons
                                    .attachment), // You can use any icon here
                                onPressed: () {
                                  // Handle the icon press action
                                  Get.bottomSheet(
                                    AttachmentBottomSheet(
                                      channelId:
                                          messageController.channelId.value,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatMessage(
      MessageModel message,
      MessageController messageController,
      FocusNode _focusNode,
      SocketService socketService) {
    bool hasImageUrl = message.url != null && message.url!.isNotEmpty;

    return Slidable(
      key: Key(message.id.toString()),
      startActionPane: message.messageDirection == "S"
          ? ActionPane(
              motion:
                  const DrawerMotion(), // Provides a smooth sliding animation

              extentRatio:
                  0.25, // Adjust the ratio to determine the action pane's width
              children: [
                CustomSlidableAction(
                    onPressed: (context) {
                      // // Trigger reply action on swipe right
                      FocusScope.of(context).requestFocus(_focusNode);
                      messageController.selectedRplyMessage.value = message;
                    },
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.grey,
                    child: Center(
                      child: Icon(
                        Icons.reply,
                        size: 32,
                        color: Colors.grey,
                      ),
                    )),
              ],
            )
          : null,
      endActionPane: message.messageDirection == "R"
          ? ActionPane(
              motion:
                  const DrawerMotion(), // Provides a smooth sliding animation

              extentRatio:
                  0.25, // Adjust the ratio to determine the action pane's width
              children: [
                CustomSlidableAction(
                    onPressed: (context) {
                      // // Trigger reply action on swipe right
                      FocusScope.of(context).requestFocus(_focusNode);
                      messageController.selectedRplyMessage.value = message;
                    },
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.grey,
                    child: Center(
                      child: Icon(
                        Icons.reply,
                        size: 32,
                        color: Colors.grey,
                      ),
                    )),
              ],
            )
          : null,
      child: Align(
        alignment: message.messageDirection == "R"
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: PopupMenuButton(
            clipBehavior: Clip.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            offset: message.messageDirection == "R"
                ? Offset.fromDirection(1.5, 70)
                : Offset(TDeviceUtils.getScreenWidth(context) * 0, 60),
            color: Colors.white,
            onSelected: (value) {
              switch (value) {
                case 'reply':
                  FocusScope.of(context).requestFocus(_focusNode);
                  messageController.selectedRplyMessage.value = message;
                  // Handle reply action
                  break;
                case 'pin':
                  socketService.pinMessage(message.id!,
                      (message.driverPin ?? "0") == "0" ? "1" : "0", "driver");
                  // Handle pin action
                  break;
                case 'delete':
                  socketService.deleteMessage(message.id!);
                  // Handle delete action
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'reply',
                child: Row(
                  children: [
                    Icon(Icons.reply, color: Colors.grey[700]),
                    SizedBox(width: 10),
                    Text(
                      "Reply",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'pin',
                child: Row(
                  children: [
                    Icon(Icons.push_pin, color: Colors.grey[700]),
                    SizedBox(width: 10),
                    Text(
                      "${message.driverPin == "0" ? "Pin" : "Un-Pin"} Message",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (message.messageDirection == "R" &&
                  message.deliveryStatus == "sent")
                const PopupMenuDivider(),
              if (message.messageDirection == "R" &&
                  message.deliveryStatus == "sent")
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Text(
                        "Delete",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            child: Column(
              crossAxisAlignment: message.messageDirection == "R"
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: TDeviceUtils.getScreenWidth(context) * 0.5,
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: message.messageDirection == "R"
                            ? Colors.blue[100]
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: message.messageDirection == "R"
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          // Display replay message body
                          if (message.r_message != null)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border(
                                    left: BorderSide(
                                        color: message.r_message
                                                    ?.messageDirection ==
                                                "R"
                                            ? Colors.blue
                                            : Colors.amber,
                                        width: 4)),
                                color: Colors.grey.shade200,
                              ),
                              width: TDeviceUtils.getScreenWidth(context) * 1,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 8.0, right: 8.0, left: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          textAlign: TextAlign.start,
                                          message.r_message?.messageDirection ==
                                                  "R"
                                              ? "You"
                                              : "${message.r_message?.sender?.username}(staff)",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    if (message.r_message?.url != null)
                                      AttachementUi(
                                        fileUrl:
                                            "${Constant.aws}/${message.r_message?.url}",
                                        thumbnail:
                                            "${Constant.aws}/${message.r_message?.thumbnail}",
                                      ),
                                    const SizedBox(height: 1),
                                    Text(
                                      message.r_message?.body ?? "-",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // If there's an image URL, show the image with a loading indicator
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
                    if (message.driverPin == "1")
                      Positioned(
                        // For messages sent by "R", place the icon at the top left,
                        // otherwise place it at the top right.
                        top: -8,
                        left: message.messageDirection == "R" ? -10 : null,
                        right: message.messageDirection != "R" ? 0 : null,
                        child: Container(
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                              color: Colors.green,
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(50)),
                          child: Center(
                            child: Transform.rotate(
                              angle: message.messageDirection == "R"
                                  ? -math.pi / 4
                                  : math.pi / 4,
                              child: Icon(
                                Icons.push_pin_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                        ),
                  ],
                )
              ],
            ),
          ),
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
                              "chat",
                              "",
                              "driver_chat",
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
                      channelId, "chat", "", "driver_chat", "");
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
