import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:uscitylink/controller/document_controller.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';

class DocumentDownload extends StatefulWidget {
  final String file; // URL of the file
  DocumentDownload({super.key, required this.file});

  @override
  State<DocumentDownload> createState() => _DocumentDownloadState();
}

class _DocumentDownloadState extends State<DocumentDownload> {
  final DocumentController _documentController = Get.put(DocumentController());
  late VideoPlayerController videoPlayerController;
  late Future<void> _initializeVideoPlayerFuture;

  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
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

  @override
  void initState() {
    super.initState();
    String extension = widget.file.split('.').last.toLowerCase();
    if (videoExtensions.contains(extension)) {
      videoPlayerController =
          new VideoPlayerController.networkUrl(Uri.parse(widget.file));

      _initializeVideoPlayerFuture =
          videoPlayerController.initialize().then((_) {
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    String extension = widget.file.split('.').last.toLowerCase();
    if (videoExtensions.contains(extension)) {
      videoPlayerController.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String extension = widget.file.split('.').last.toLowerCase();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                // Implement download logic
                if (['png', 'jpg', 'jpeg'].contains(extension)) {
                  _documentController.saveImageToGallery(widget.file);
                } else if (videoExtensions.contains(extension)) {
                  _documentController.saveImageToGallery(widget.file);
                } else if (extension == 'pdf') {
                  _documentController.downloadFile(widget.file);
                } else {
                  _documentController.downloadFile(widget.file);
                  // Get.snackbar("Error", "Unsupported file type");
                }
              },
              icon: const Icon(
                Icons.download,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () {
                _shareFile(widget.file);
              },
              icon: const Icon(
                Icons.share,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              if (['png', 'jpg', 'jpeg'].contains(extension))
                _buildImagePreview(widget.file)
              else if (extension == 'pdf')
                _buildPdfPreview(widget.file)
              else if (videoExtensions.contains(extension))
                FutureBuilder(
                  future: _initializeVideoPlayerFuture,
                  builder: (context, snapshot) {
                    return (snapshot.connectionState == ConnectionState.done)
                        ? Stack(
                            children: [
                              Positioned.fill(
                                top: 0,
                                left: 0,
                                right: 0,
                                //height: TDeviceUtils.getScreenHeight() - 100,
                                child: Chewie(
                                  // key: new PageStorageKey(widget.url),
                                  controller: ChewieController(
                                    videoPlayerController:
                                        videoPlayerController,
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
                            ],
                          )
                        : SizedBox(
                            height: 200,
                            child: Center(
                              child: (snapshot.connectionState !=
                                      ConnectionState.none)
                                  ? CircularProgressIndicator()
                                  : SizedBox(),
                            ),
                          );
                  },
                )
              else
                _buildPdfPreview(widget.file)
              // const Center(
              //     child: Text("Unsupported File Type",
              //         style: TextStyle(fontSize: 18, color: Colors.red))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareFile(fileUrl) async {
    try {
      // Get the file from the cache
      // final file = await DefaultCacheManager().getSingleFile(fileUrl);

      // Share the file using share_plus
      await Share.shareUri(Uri.parse(fileUrl));

      // Show a confirmation message
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(content: Text("Sharing file...")),
      );
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text("Share failed: $e")),
      );
    }
  }

  // Function to download the file
  void _downloadFile() async {
    try {
      var fileInfo = await DefaultCacheManager().getSingleFile(widget.file);
      print('File downloaded: ${fileInfo.path}');
      ScaffoldMessenger.of(Get.context!).showSnackBar(
          const SnackBar(content: Text("File downloaded successfully!")));
    } catch (e) {
      print("Download failed: $e");
      ScaffoldMessenger.of(Get.context!)
          .showSnackBar(const SnackBar(content: Text("Download failed")));
    }
  }

  Future<void> _download(String fileUrl) async {
    try {
      // Get file extension
      String extension = fileUrl.split('.').last.toLowerCase();

      // Fetch the file from the URL
      final file = await DefaultCacheManager().getSingleFile(fileUrl);

      // Get the appropriate directory to store the file
      Directory appDocDirectory = await getApplicationDocumentsDirectory();
      String localPath =
          '${appDocDirectory.path}/${file.uri.pathSegments.last}';

      // Copy the file from the cache to the local directory
      final savedFile = await file.copy(localPath);

      // Show confirmation
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text("File downloaded to $localPath")),
      );
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  // Widget to build the image preview
  Widget _buildImagePreview(String imageUrl) {
    return Center(
      child: Container(
        constraints: BoxConstraints
            .expand(), // Ensure the container takes the full screen
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit
              .contain, // This will make the image fit within the screen while preserving aspect ratio
          imageBuilder: (context, imageProvider) {
            return PhotoView(
              imageProvider: imageProvider,
              minScale: PhotoViewComputedScale
                  .contained, // Image will be contained within the screen
              maxScale: PhotoViewComputedScale
                  .covered, // Image can zoom up to cover the screen
            );
          },
          placeholder: (context, url) =>
              Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
      ),
    );
  }

  // Widget to build the PDF preview using flutter_pdfview
  Widget _buildPdfPreview(String pdfUrl) {
    return FutureBuilder(
      future: DefaultCacheManager().getSingleFile(pdfUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          print(snapshot.error);
          return const Center(child: Text('Error loading PDF'));
        } else if (snapshot.hasData) {
          // You can now use PDFView from the flutter_pdfview package
          return SizedBox(
            width: double.infinity,
            height:
                TDeviceUtils.getScreenHeight() * 0.8, // Adjust height as needed
            child: SfPdfViewer.network(
              pdfUrl,
              key: _pdfViewerKey,
            ),
          );
        } else {
          return const Center(child: Text('No PDF data available'));
        }
      },
    );
  }
}
