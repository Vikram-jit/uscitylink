import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:pdf_render/pdf_render_widgets.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/media_controller.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/views/widgets/document_download.dart';

class CustomWidget {
  static Widget buildSegmentButton(int index, String label,
      MediaController mediaController, BuildContext context) {
    return GestureDetector(
      onTap: () {
        mediaController.selectSegment(index);
      },
      child: AnimatedContainer(
        width: TDeviceUtils.getScreenWidth(context) * 0.43,
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: mediaController.selectedSegment.value == index
              ? Colors.white
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: mediaController.selectedSegment.value == index
                  ? Colors.black
                  : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 10),
        ),
      ),
    );
  }

  // Build a GridView for Media tab
  static Widget buildMediaGrid(MediaController mediaController) {
    List<String> videoExtensions = [
      'mp4',
      'mkv',
      'avi',
      'mov',
      'flv',
      'webm',
      'mpeg',
      'mpg',
      'wmv'
    ];

    if (mediaController.mediaList.isEmpty) {
      return const Center(
        child: Text("No Media"),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: mediaController.mediaList.length,
      itemBuilder: (context, index) {
        if (index == mediaController.mediaList.length) {
          // Show loading indicator if the page is still loading
          return mediaController.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox.shrink();
        }

        final mediaItem = mediaController.mediaList[index];
        String extension = mediaItem.key!.split('.').last.toLowerCase();

        return GestureDetector(
          onTap: () {
            final file = '${Constant.aws}/${mediaItem.key}';
            Get.to(() => DocumentDownload(file: file));
          },
          child: videoExtensions.contains(extension)
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        '${Constant.aws}/${mediaItem.thumbnail}',
                        fit: BoxFit.cover, // Ensure image fits within the space
                        height: double.infinity,
                        width: double.infinity,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            return child; // If image has loaded, return the image
                          } else {
                            // Display loading progress
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.play_circle,
                        color: Colors.white,
                        size: 28,
                      ),
                    )
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    '${Constant.aws}/${mediaItem.key}',
                    fit: BoxFit.cover, // Ensure image fits within the space
                    height: double.infinity,
                    width: double.infinity,
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child; // If image has loaded, return the image
                      } else {
                        // Display loading progress
                        return Center(
                          child: CircularProgressIndicator(
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
        );
      },
      controller: mediaController.scrollController
        ..addListener(() {
          if (mediaController.isLoading.value) return;

          if (mediaController.mediaList.isNotEmpty &&
              mediaController.scrollController.position.pixels ==
                  mediaController.scrollController.position.maxScrollExtent) {
            // Load more media when scrolling reaches the bottom
            //mediaController.fetchMediaData(channelId);
          }
        }),
    );
  }

  // Build a GridView for Docs tab
  static Widget buildDocsGrid(MediaController mediaController) {
    final controller = PdfViewerController();
    if (mediaController.mediaList.isEmpty) {
      return const Center(
        child: Text("No Document"),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      shrinkWrap: true, // Use it inside SingleChildScrollView
      physics: const AlwaysScrollableScrollPhysics(), // Enable scrolling
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Set the number of columns
        crossAxisSpacing: 10, // Spacing between columns
        mainAxisSpacing: 10, // Spacing between rows
        childAspectRatio: 1, // Aspect ratio of each grid item
      ),
      itemCount: mediaController
          .mediaList.length, // Example: Show 10 items in the grid
      itemBuilder: (context, index) {
        final mediaItem = mediaController.mediaList[index];
        return GestureDetector(
          onTap: () async {
            // Navigate to PDF preview screen on tap
            final file = '${Constant.aws}/${mediaItem.key}';
            Get.to(() => DocumentDownload(file: file));
          },
          child: Container(
            height: 200.0,
            color: Colors.grey[200],
            child: FutureBuilder(
              future: DefaultCacheManager()
                  .getSingleFile('${Constant.aws}/${mediaItem.key}'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(
                      child: Icon(Icons.error, size: 40, color: Colors.red));
                } else if (snapshot.hasData) {
                  // If the file is cached, show the PDF thumbnail
                  return PdfViewer.openFutureFile(
                    () async => snapshot.data!.path,
                    viewerController: controller,
                    params: const PdfViewerParams(padding: 0),
                  );
                } else {
                  return const Center(child: Text('Failed to load PDF'));
                }
              },
            ),
          ),
        );
      },
      controller: mediaController.scrollController
        ..addListener(() {
          if (mediaController.isLoading.value) return;

          if (mediaController.mediaList.isNotEmpty &&
              mediaController.scrollController.position.pixels ==
                  mediaController.scrollController.position.maxScrollExtent) {
            // Load more media when scrolling reaches the bottom
            //mediaController.fetchMediaData(channelId);
          }
        }),
    );
  }
}
