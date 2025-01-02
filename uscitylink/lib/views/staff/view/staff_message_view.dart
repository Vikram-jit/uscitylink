import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/file_picker_controller.dart';
import 'package:uscitylink/controller/image_picker_controller.dart';
import 'package:uscitylink/controller/staff/staffchat_controller.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/utils/constant/Colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/driver/views/chats/attachement_ui.dart';

class StaffMessageView extends StatelessWidget {
  final String channelId;
  final String userId;
  final String name;
  StaffMessageView(
      {super.key,
      required this.channelId,
      required this.userId,
      required this.name});
  StaffchatController _staffchatController = Get.put(StaffchatController());
  @override
  Widget build(BuildContext context) {
    //WidgetsBinding.instance.addPostFrameCallback((_) {
    // This ensures any state change happens after the widget build is complete.
    _staffchatController.getChannelMembers(userId);
    // });
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            )),
        backgroundColor: TColors.primaryStaff,
        title: Text(
          "${name}",
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
            padding: EdgeInsets.all(TDeviceUtils.getScreenHeight() * 0.01),
            child: Obx(() {
              if (_staffchatController.loading.value == true) {
                return Center(
                  child: CircularProgressIndicator(
                    color: TColors.primaryStaff,
                  ),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        _staffchatController.getChannelMembers(channelId);
                      },
                      child: Obx(() {
                        if (_staffchatController
                                .message.value.messages?.length ==
                            0) {
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
                                  Text("Say Hi",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                              color: Colors.grey.shade700))
                                ],
                              ),
                            ),
                          ));
                        }
                        return ListView.builder(
                          reverse: true,
                          itemCount: _staffchatController
                              .message.value.messages?.length,
                          itemBuilder: (context, index) {
                            MessageModel message =
                                _staffchatController.message.value.messages![0];

                            return _buildChatMessage(message, context);
                          },
                        );
                      }),
                    ),
                  ),
                  // Obx(() {
                  //   return messageController.typing.value
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
                  //                     messageController.typingMessage.value);
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
                            onChanged: (text) {
                              if (text.isNotEmpty) {
                              } else {}
                            },
                            // controller: _controller,
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
                                      channelId: channelId,
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
                          onTap: () {},
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
            })),
      ),
    );
  }

  Widget _buildChatMessage(MessageModel message, BuildContext context) {
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
                      channelId, "chat", "");
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
                      channelId, "chat", "");
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
                      channelId, "chat", "");
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
