import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/image_picker_controller.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/utils/utils.dart';

class Messageui extends StatefulWidget {
  final dynamic channelId;
  final String name;
  Messageui({required this.channelId, super.key, required this.name});

  @override
  _MessageuiState createState() => _MessageuiState();
}

class _MessageuiState extends State<Messageui> {
  final TextEditingController _controller = TextEditingController();

  late MessageController messageController;
  SocketService socketService = Get.put(SocketService());

  @override
  void initState() {
    super.initState();

    // Initialize the MessageController and fetch messages for the given channelId
    messageController = Get.put(MessageController());
    messageController.getChannelMessages(
        widget.channelId); // Fetch the messages for the given channelId
  }

  // Function to send a new message
  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      socketService.sendMessage(_controller.text, null);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Column(
          children: [
            AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name, // Display the channel name
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  // Text(
                  //   lastLogin, // Display the last login info
                  //   style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  // ),
                ],
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back), // Back icon
                onPressed: () {
                  // Trigger the socket event when the back icon is clicked
                  socketService.updateActiveChannel("");
                  Navigator.pop(
                      context); // This will pop the current screen and go back to the previous screen
                },
              ),
              actions: [
                Icon(Icons.add_a_photo),
                SizedBox(
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
      body: Padding(
        padding: EdgeInsets.all(TDeviceUtils.getAppBarHeight() * 0.4),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  messageController.getChannelMessages(widget.channelId);
                },
                child: Obx(() {
                  if (messageController.messages.isEmpty) {
                    return Center(
                        child: Container(
                      height: 100,
                      width: 100,
                      child: InkWell(
                        onTap: () {
                          socketService.sendMessage("Hi", null);
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Text Field for typing the message
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(
                              Icons.attachment), // You can use any icon here
                          onPressed: () {
                            // Handle the icon press action
                            Get.bottomSheet(
                              AttachmentBottomSheet(),
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
                      child: Icon(
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
                    Image.network(
                      "${Constant.aws}/${message.url!}",
                      width: TDeviceUtils.getScreenWidth(context) * 0.5,
                      height: 150, // Set image height
                      fit: BoxFit.cover, // Maintain aspect ratio
                      loadingBuilder: (context, child, loadingProgress) {
                        // If the image is still loading, show the progress indicator
                        if (loadingProgress == null) {
                          return child; // Image loaded
                        } else {
                          return Container(
                            width: TDeviceUtils.getScreenWidth(context) * 0.5,
                            height: 150, // Set image height
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                              ),
                            ),
                          );
                        }
                      },
                      errorBuilder: (context, error, stackTrace) {
                        // Handle error when loading the image
                        return const Icon(
                          Icons.error,
                          size: 40,
                          color: Colors.red,
                        );
                      },
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
          ],
        ),
      ),
    );
  }
}

class AttachmentBottomSheet extends StatelessWidget {
  final ImagePickerController imagePickerController =
      Get.put(ImagePickerController());
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
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
                  imagePickerController.pickImageFromGallery();
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
                  imagePickerController.pickImageFromCamera();
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
            ],
          )
        ],
      ),
    );
  }
}
