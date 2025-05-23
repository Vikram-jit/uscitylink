import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/image_picker_controller.dart';
import 'package:uscitylink/services/network_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';

class PhotoPreviewScreen extends StatelessWidget {
  final String channelId;
  final String type;
  final String location;
  final String? groupId;
  final String? source;
  final String? userId;
  // Access the controller instance
  final ImagePickerController controller = Get.find();
  SocketService _socketService = Get.find<SocketService>();
  NetworkService _networkService = Get.find<NetworkService>();

  PhotoPreviewScreen(
      {super.key,
      required this.channelId,
      required this.type,
      required this.location,
      this.groupId,
      this.userId,
      this.source});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        // If the image is still loading, show the loader
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: TColors.secondary, // Custom loader color
            ),
          );
        }
        return Stack(
          children: [
            // Display the selected image in full-screen
            Center(
              child: Obx(() {
                if (controller.selectedImage.value != null) {
                  return Image.file(
                    controller.selectedImage.value!,
                    fit: BoxFit.fitWidth,
                    height: double.infinity,
                    width: double.infinity,
                  );
                } else {
                  return const SizedBox();
                }
              }),
            ),

            // Transparent black overlay with caption at the bottom
            Positioned(
              bottom: 15,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.black
                      .withOpacity(0.6), // Transparent black background
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      onChanged: (text) {
                        controller.setCaption(text); // Update the caption
                      },
                      decoration: InputDecoration(
                        focusColor: Colors.white,
                        hintText: 'Add a caption...',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.7)),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.3),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        suffixIcon: InkWell(
                          onTap: () {
                            controller.uploadFile(channelId, type, location,
                                groupId, source, userId);
                          },
                          child: const Icon(
                            Icons.send,
                            color: TColors.secondary,
                          ),
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.white, // White text for the caption
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top-left Close Image Button (Clear and Pick Image)
            Positioned(
              top: 60,
              right: 20,
              child: InkWell(
                onTap: () {
                  // controller.selectedSource.value == "gallery"
                  //     ? controller.pickImageFromGallery()
                  //     : controller.pickImageFromCamera();

                  controller.clearSelectedImage();
                  Get.back();
                },
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
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
          ],
        );
      }),
    );
  }
}
