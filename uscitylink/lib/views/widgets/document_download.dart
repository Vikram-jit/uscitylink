import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:uscitylink/controller/document_controller.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';
import 'package:pdfrx/pdfrx.dart';

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

  // final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
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

  Future<void> _shareFile(String fileUrl) async {
    BuildContext? context = Get.context;

    try {
      if (context == null) return;

      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Download file
      File? localFile = await _downloadFile(fileUrl);

      // Close loading
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // ❌ If download failed, stop here
      if (localFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to download file"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final box = context.findRenderObject() as RenderBox?;

      // ✅ iOS share with position
      if (Platform.isIOS && box != null) {
        await Share.shareXFiles(
          [XFile(localFile.path)],
          text: 'Check out this file!',
          subject: 'Shared from ChatBox',
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        );
      } else {
        // ✅ Android / fallback
        await Share.shareXFiles(
          [XFile(localFile.path)],
          text: 'Check out this file!',
        );
      }

      // Success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("File shared successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Share failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _getUniqueFilePath(String filePath) async {
    int counter = 1;
    String newPath = filePath;

    while (await File(newPath).exists()) {
      final extension = filePath.contains('.')
          ? filePath.substring(filePath.lastIndexOf('.'))
          : '';

      final name = filePath.replaceAll(extension, '');

      newPath = "${name}_$counter$extension";
      counter++;
    }

    return newPath;
  }

  Future<File?> _downloadFile(String fileUrl) async {
    try {
      if (fileUrl.trim().isEmpty) {
        throw Exception("Invalid file URL");
      }

      final uri = Uri.tryParse(fileUrl);
      if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        throw Exception("Invalid URL format");
      }

      print('📥 Downloading: $fileUrl');

      // Download using cache manager
      final file = await DefaultCacheManager().getSingleFile(fileUrl);

      if (!await file.exists()) {
        throw Exception("File not found after download");
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception("Downloaded file is empty");
      }

      print("📦 File size: ${_formatFileSize(fileSize)}");

      // Get app directory
      final directory = await getApplicationDocumentsDirectory();

      final downloadDir = Directory('${directory.path}/Downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Generate safe filename
      final fileName = _generateSafeFileName(uri);
      String savePath = '${downloadDir.path}/$fileName';

      savePath = await _getUniqueFilePath(savePath);

      final savedFile = await file.copy(savePath);

      print("✅ Saved at: $savePath");

      return savedFile;
    } catch (e) {
      print("❌ Download error: $e");

      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }

      return null;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error == null) {
      return "Something went wrong";
    }

    // 🔌 Network errors
    if (error is SocketException) {
      return "No internet connection";
    }

    // ⏳ Timeout
    if (error is TimeoutException) {
      return "Connection timeout. Please try again";
    }

    // 🌐 HTTP errors
    if (error is HttpException) {
      return "Server error occurred";
    }

    // 📂 File system errors
    if (error is FileSystemException) {
      if (error.osError?.message.contains("No space") ?? false) {
        return "Insufficient storage space";
      }
      return "Storage access error";
    }

    // 📱 Platform specific errors
    if (error is PlatformException) {
      if (error.message?.toLowerCase().contains("permission") ?? false) {
        return "Permission denied";
      }
      return error.message ?? "Platform error occurred";
    }

    // 🔎 String fallback checks
    final message = error.toString().toLowerCase();

    if (message.contains("404")) {
      return "File not found";
    }

    if (message.contains("403")) {
      return "Access denied";
    }

    if (message.contains("network")) {
      return "Network error";
    }

    if (message.contains("timeout")) {
      return "Connection timeout";
    }

    if (message.contains("empty")) {
      return "Downloaded file is empty";
    }

    if (message.contains("permission")) {
      return "Permission denied";
    }

    return "Something went wrong. Please try again";
  }

  String _generateSafeFileName(Uri uri) {
    String name = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';

    if (name.isEmpty || !name.contains('.')) {
      return 'file_${DateTime.now().millisecondsSinceEpoch}.bin';
    }

    return name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";

    const units = ["B", "KB", "MB", "GB", "TB"];
    int index = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && index < units.length - 1) {
      size /= 1024;
      index++;
    }

    return "${size.toStringAsFixed(2)} ${units[index]}";
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
            child: PdfViewer.uri(
              Uri.parse(pdfUrl),
            ),
            // child: Center(
            //     child: Text(
            //   "PDF Preview Unavailables",
            //   style: TextStyle(color: Colors.red),
            // )),
          );
        } else {
          return const Center(child: Text('No PDF data available'));
        }
      },
    );
  }
}
