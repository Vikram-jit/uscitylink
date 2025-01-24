import 'package:flutter/material.dart';
import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/image_picker_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  final File path;
  final String channelId;
  final String type;
  final String location;
  final String? groupId;
  final String? source;
  final String? userId;

  VideoPreviewScreen(
      {Key? key,
      required this.path,
      required this.channelId,
      required this.type,
      required this.location,
      this.groupId,
      this.source,
      this.userId})
      : super(key: key);

  @override
  _VideoPreviewScreenState createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController videoPlayerController;

  late Future<void> _initializeVideoPlayerFuture;
  final ImagePickerController controller = Get.find();

  @override
  void initState() {
    super.initState();
    videoPlayerController = new VideoPlayerController.file(widget.path);

    _initializeVideoPlayerFuture = videoPlayerController.initialize().then((_) {
      //       Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
      setState(() {});
    });
  }

  @override
  void dispose() {
    videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                color: TColors.secondary, // Custom loader color
              ),
            );
          }
          return FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              return (snapshot.connectionState == ConnectionState.done)
                  ? Stack(
                      children: [
                        Positioned.fill(
                          bottom: 100,
                          left: 0,
                          right: 0,
                          //height: TDeviceUtils.getScreenHeight() - 100,
                          child: Chewie(
                            // key: new PageStorageKey(widget.url),
                            controller: ChewieController(
                              videoPlayerController: videoPlayerController,
                              autoInitialize: true,
                              looping: true,
                              showOptions: false,
                              allowFullScreen: false,
                              errorBuilder: (context, errorMessage) {
                                return Center(
                                  child: Text(
                                    errorMessage,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: TDeviceUtils.getScreenHeight() * 0.05,
                          right: TDeviceUtils.getScreenWidth(context) * 0.05,
                          child: SizedBox(
                            height: TDeviceUtils.getScreenHeight() * 0.05,
                            child: GestureDetector(
                              onTap: () {
                                Get.back();
                              },
                              child: Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.close, // Use a different icon if needed
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(
                                  0.6), // Transparent black background
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  onChanged: (text) {
                                    controller
                                        .setCaption(text); // Update the caption
                                  },
                                  decoration: InputDecoration(
                                    focusColor: Colors.white,
                                    hintText: 'Add a caption...',
                                    hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.7)),
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.3),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    suffixIcon: InkWell(
                                      onTap: () {
                                        controller.uploadFileVideo(
                                            widget.channelId,
                                            widget.type,
                                            widget.location,
                                            widget.groupId,
                                            widget.source,
                                            widget.userId);
                                      },
                                      child: const Icon(
                                        Icons.send,
                                        color: TColors.secondary,
                                      ),
                                    ),
                                  ),
                                  style: const TextStyle(
                                    color: Colors
                                        .white, // White text for the caption
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      height: 200,
                      child: Center(
                        child:
                            (snapshot.connectionState != ConnectionState.none)
                                ? CircularProgressIndicator()
                                : SizedBox(),
                      ),
                    );
            },
          );
        }));
  }
}
