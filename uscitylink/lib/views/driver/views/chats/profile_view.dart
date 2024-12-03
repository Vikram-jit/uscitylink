import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:pdf_render/pdf_render_widgets.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/media_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/views/widgets/document_download.dart';
import 'package:uscitylink/widegts/CustomWidget.dart';

class ProfileView extends StatelessWidget {
  final String channelId;
  const ProfileView({super.key, required this.channelId});

  @override
  Widget build(BuildContext context) {
    // Use the channelId in the controller
    final mediaController =
        Get.put(MediaController(channelId: channelId, source: "channel"));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColors.primary,
        centerTitle: true,
        title: Obx(() {
          return Text(
            "${mediaController.channel.value.name}",
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
              int selectedIndex = mediaController.selectedSegment.value;
              if (selectedIndex == 0) {
                return CustomWidget.buildMediaGrid(
                    mediaController); // Grid for Media Tab
              } else if (selectedIndex == 1) {
                return CustomWidget.buildDocsGrid(
                    mediaController); // Grid for Docs Tab
              }
              return Container(); // Default empty container
            }),
          ),
        ],
      ),
    );
  }
}
