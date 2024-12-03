import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/media_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/widegts/CustomWidget.dart';

class GroupMedia extends StatefulWidget {
  final String groupId;
  GroupMedia({super.key, required this.groupId});

  @override
  State<GroupMedia> createState() => _GroupMediaState();
}

class _GroupMediaState extends State<GroupMedia> {
  late MediaController mediaController; // Declare the controller

  @override
  void initState() {
    super.initState();
    // Initialize the mediaController directly in initState
    mediaController =
        Get.put(MediaController(channelId: widget.groupId, source: "group"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColors.primary,
        centerTitle: true,
        title: Obx(() {
          // Ensure that the channel is properly loaded before displaying its name
          if (mediaController.channel.value == null) {
            return Text(
              'Loading...', // Display loading text if the channel is null
              style: TextStyle(color: Colors.white),
            );
          }
          return Text(
            mediaController.channel.value?.name ?? 'No Channel', // Channel name
            style: TextStyle(color: Colors.white),
          );
        }),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          // Tab Bar for Media and Docs
          Obx(() {
            return Container(
              width: TDeviceUtils.getScreenWidth(context) * 0.90,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5)),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CustomWidget.buildSegmentButton(
                      0, 'Media', mediaController, context),
                  CustomWidget.buildSegmentButton(
                      1, 'Docs', mediaController, context),
                ],
              ),
            );
          }),
          const SizedBox(height: 30),
          // Scrollable Grid Area
          Expanded(
            child: Obx(() {
              // Ensure the mediaController's selectedSegment value is valid
              if (mediaController.selectedSegment.value == null) {
                return Center(child: CircularProgressIndicator());
              }

              int selectedIndex = mediaController.selectedSegment.value ?? 0;

              // Switch between Media and Docs grids based on the selected segment
              if (selectedIndex == 0) {
                return CustomWidget.buildMediaGrid(
                    mediaController); // Media Tab
              } else if (selectedIndex == 1) {
                return CustomWidget.buildDocsGrid(mediaController); // Docs Tab
              }
              return Container(); // Default empty container if no valid segment
            }),
          ),
        ],
      ),
    );
  }
}
