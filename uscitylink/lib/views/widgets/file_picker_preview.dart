import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/file_picker_controller.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';

class FilePickerPreview extends StatelessWidget {
  final String channelId;
  final String type;
  final String location;
  final String? groupId;
  final String? source;
  final String? userId;
  // Initialize the controller
  final FilePickerController _controller = Get.put(FilePickerController());

  FilePickerPreview(
      {super.key,
      required this.channelId,
      required this.type,
      required this.location,
      this.groupId,
      this.source,
      this.userId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: const Icon(Icons.close),
            color: Colors.white,
          ),
          title: Text(
            "${_controller.fileName}",
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Display file preview for PDF
              Obx(() {
                if (_controller.filePath.value.isNotEmpty &&
                    _controller.fileType.value == 'pdf') {
                  return SizedBox(
                    height: TDeviceUtils.getScreenHeight() * 0.65,
                    // child: PDFView(
                    //   filePath: _controller.filePath.value,
                    //   onPageChanged: (int? currentPage, int? totalPages) {
                    //     // Update the current page and total pages when the page changes
                    //     _controller.updatePDFPage(
                    //         currentPage ?? 0, totalPages ?? 0);
                    //   },
                    // ),
                    child: Center(
                      child: Text("PDF Preview Unavailable"),
                    ),
                  );
                } else {
                  return const SizedBox(); // No preview for non-PDF files
                }
              }),

              const SizedBox(height: 5),

              // Display the current page and total pages for PDF
              Obx(() {
                if (_controller.fileType.value == 'pdf') {
                  return Text(
                    "Page ${_controller.currentPage.value + 1} of ${_controller.totalPages.value}",
                    style: const TextStyle(color: Colors.white),
                  );
                }
                return const SizedBox(); // Hide for non-PDF files
              }),
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
                        _controller.setCaption(text); // Update the caption
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
                            _controller.uploadFile(channelId, type, location,
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
              // Button to open the selected file
            ],
          ),
        ),
      ),
    );
  }
}
