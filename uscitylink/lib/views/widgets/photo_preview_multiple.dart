import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/image_picker_controller.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/services/network_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';

class PhotoPreviewMultiple extends StatefulWidget {
  final String channelId;
  final String type;
  final String uploadBy;
  final String location;
  final String? groupId;
  final String? source;
  final String? userId;

  PhotoPreviewMultiple({
    super.key,
    required this.channelId,
    required this.type,
    required this.location,
    required this.uploadBy,
    this.groupId,
    this.userId,
    this.source,
  });

  @override
  State<PhotoPreviewMultiple> createState() => _PhotoPreviewMultipleState();
}

class _PhotoPreviewMultipleState extends State<PhotoPreviewMultiple> {
  // Access the controller instance
  final ImagePickerController controller = Get.find();
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  ScrollController _scrollController = ScrollController();
  SocketService _socketService = Get.find<SocketService>();
  NetworkService _networkService = Get.find<NetworkService>();
  UserPreferenceController _userPreferenceController =
      Get.put(UserPreferenceController());
  int _currentIndex = 0;

  void _removeImage(int index) {
    controller.selectedImages.value.removeAt(index);
    if (index < controller.selectedXImages.value.length) {
      controller.selectedXImages.value.removeAt(index);
    }
    controller.selectedImages.refresh();
    controller.selectedXImages.refresh();

    if (controller.selectedImages.value.isEmpty) {
      controller.clearSelectedImage();
      Get.back();
      return;
    }

    setState(() {
      if (_currentIndex >= controller.selectedImages.value.length) {
        _currentIndex = controller.selectedImages.value.length - 1;
      }
    });
    _carouselController.animateToPage(_currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            controller.clearSelectedImage();
            Get.back();
          },
          icon: Icon(Icons.arrow_back_ios),
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: TColors.secondary,
            ),
          );
        }
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        return Column(
          children: [
            SizedBox(
              height: (TDeviceUtils.getScreenHeight() * 0.7 -
                      TDeviceUtils.getAppBarHeight() -
                      keyboardHeight)
                  .clamp(0.0, double.infinity),
              child: Obx(() {
                if (controller.selectedImages.value.isNotEmpty) {
                  return CarouselSlider(
                    carouselController: _carouselController,
                    items: controller.selectedImages.value.map((item) {
                      return SizedBox(
                        height: TDeviceUtils.getScreenHeight() * 0.8,
                        child: Image.file(item, fit: BoxFit.contain),
                      );
                    }).toList(),
                    options: CarouselOptions(
                      height: TDeviceUtils.getScreenHeight() * 0.8,
                      autoPlay: false,
                      enlargeCenterPage: true,
                      onPageChanged: (index, reason) {
                        // _scrollController.animateTo(
                        //   index * 100,
                        //   duration: Duration(milliseconds: 500),
                        //   curve: Curves.easeInOut,
                        // );
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                    ),
                  );
                } else {
                  return const SizedBox();
                }
              }),
            ),
            Obx(() {
              return SizedBox(
                height: 100,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.selectedImages.value.length + 1,
                  itemBuilder: (context, index) {
                    if (index == controller.selectedImages.value.length) {
                      return GestureDetector(
                        onTap: () async {
                          await controller.addImageFromCamera();
                          setState(() {
                            _currentIndex =
                                controller.selectedImages.value.length - 1;
                          });
                          _carouselController.animateToPage(_currentIndex);
                        },
                        child: Container(
                          width: 50.0,
                          height: 50.0,
                          margin: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 6.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, color: Colors.grey),
                        ),
                      );
                    }
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _carouselController.animateToPage(index);
                          },
                          child: Container(
                            width: 90.0,
                            height: 50.0,
                            margin: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 2.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _currentIndex == index
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                            ),
                            child: Image.file(
                                controller.selectedImages.value[index],
                                fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: -2,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              height: 18,
                              width: 18,
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            }),

            // Transparent black overlay with caption at the bottom
            Container(
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
                        onTap: () async {
                          // if (_networkService.connected == false) {
                          //   controller.uploadMultiFileOffline(
                          //       widget.channelId,
                          //       widget.type,
                          //       widget.location,
                          //       widget.groupId,
                          //       widget.source,
                          //       widget.userId,
                          //       widget.uploadBy);
                          // } else if (_socketService.isConnected.value ==
                          //     false) {
                          final role =
                              await _userPreferenceController.getRole();

                          if (role == 'driver') {
                            controller.uploadMultiFileOffline(
                                widget.channelId,
                                widget.type,
                                widget.location,
                                widget.groupId,
                                widget.source,
                                widget.userId,
                                widget.uploadBy);
                          } else {
                            controller.uploadMultiFile(
                                widget.channelId,
                                widget.type,
                                widget.location,
                                widget.groupId,
                                widget.source,
                                widget.userId,
                                widget.uploadBy);
                          }
                          // } else {
                          //   controller.uploadMultiFile(
                          //       widget.channelId,
                          //       widget.type,
                          //       widget.location,
                          //       widget.groupId,
                          //       widget.source,
                          //       widget.userId,
                          //       widget.uploadBy);
                          // }
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

            // Top-left Close Image Button (Clear and Pick Image)
          ],
        );
      }),
    );
  }
}
