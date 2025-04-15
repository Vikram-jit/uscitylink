import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:pdf_render/pdf_render_widgets.dart';
import 'package:uscitylink/views/widgets/audio_player_widget.dart';
import 'package:uscitylink/views/widgets/document_download.dart';
import 'package:path/path.dart' as p;

class AttachementUi extends StatefulWidget {
  final String url_upload_type;
  final String fileUrl;
  final String thumbnail;
  final bool direction;
  final String directionType;
  final String location;
  final String localFilePath;
  AttachementUi(
      {super.key,
      required this.fileUrl,
      required this.directionType,
      this.thumbnail = "",
      this.url_upload_type = "server",
      this.direction = false,
      this.location = "driver",
      this.localFilePath = ""});

  @override
  State<AttachementUi> createState() => _AttachementUiState();
}

class _AttachementUiState extends State<AttachementUi> {
  // URL of the file to preview
  final controller = PdfViewerController();

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

  List<String> supportedAudioFormats = [
    '.mp3', // MPEG Layer III Audio
    '.aac', // Advanced Audio Coding
    '.m4a', // MPEG-4 Audio
    '.wav', // Waveform Audio File Format
    '.ogg', // Ogg Vorbis
    '.flac', // Free Lossless Audio Codec
    '.aiff', // Audio Interchange File Format
    '.amr', // Adaptive Multi-Rate Audio
    '.ape', // Monkey's Audio
    '.au', // Sun Microsystems Audio
  ];
  @override
  Widget build(BuildContext context) {
    // Extract file extension (lowercase for consistency)
    String extension = widget.fileUrl.split('.').last.toLowerCase();

    // Check for file extension and display corresponding preview
    if (['png', 'jpg', 'jpeg'].contains(extension)) {
      // Image files (PNG, JPG, JPEG)
      return _buildImagePreview(widget.fileUrl, widget.url_upload_type);
    } else if (extension == 'pdf') {
      // PDF file
      return _buildPdfPreview(widget.fileUrl);
    } else if (videoExtensions.contains(extension)) {
      return _buildVideoPreview(widget.fileUrl, widget.thumbnail);
    } else if (isSupportedFormat(widget.fileUrl)) {
      return AudioPlayerWidget(audioUrl: widget.fileUrl);
    } else {
      // Unknown or unsupported file type
      return _buildUnsupportedFile();
    }
  }

  Widget _buildVideoPreview(String imageUrl, String thumbnail) {
    return InkWell(
      onTap: () {
        // Navigate to full-screen image view (if necessary)
        Get.to(() => DocumentDownload(
              file: imageUrl,
            ));
      },
      child: SizedBox(
        width: double.infinity,
        height: 200.0,
        child: Stack(
          children: [
            Image.network(
              thumbnail,
              width: double.infinity,
              height: 200.0,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child; // Image loaded
                } else {
                  return SizedBox(
                    width: double.infinity,
                    height: 200.0,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                (loadingProgress.expectedTotalBytes ?? 1)
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
            Center(
                child: Icon(
              Icons.play_circle,
              color: Colors.white,
              size: 42,
            ))
          ],
        ),
      ),
    );
  }

  bool isSupportedFormat(String filePath) {
    // Extract the file extension
    String extension = p.extension(filePath).toLowerCase();
    print(supportedAudioFormats.contains(extension));
    // Check if the extension is in the list of supported formats
    return supportedAudioFormats.contains(extension);
  }

  // Widget to show the image preview (network image)
  Widget _buildImagePreview(String imageUrl, String url_upload_type) {
    if (url_upload_type == "local-file") {
      return Image.file(
        File(widget.localFilePath),
        width: double.infinity,
        height: 200.0,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.error,
          size: 40,
          color: Colors.red,
        ),
      );
    }
    if (url_upload_type == "not-upload") {
      return widget.direction &&
              widget.location == "driver" &&
              widget.directionType == "R"
          ? Container(
              height: 200,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular progress indicator
                      SizedBox(
                        height: 60.0,
                        width: 60.0,
                        child: CircularProgressIndicator(),
                      ),
                      // Centered icon
                      Icon(
                        widget.location == "driver" &&
                                widget.directionType == "R"
                            ? Icons.cloud_upload
                            : Icons.download,
                        size: 32.0,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    "${widget.location == "driver" && widget.directionType == "R" ? "sending..." : "receiving..."}",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  )
                ],
              ),
            )
          : Container(
              height: 200,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular progress indicator
                      SizedBox(
                        height: 60.0,
                        width: 60.0,
                        child: CircularProgressIndicator(),
                      ),
                      // Centered icon
                      Icon(
                        widget.location == "staff" &&
                                widget.directionType == "S"
                            ? Icons.cloud_upload
                            : Icons.download,
                        size: 32.0,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    "${widget.location == "staff" && widget.directionType == "S" ? "sending..." : "receiving..."}",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  )
                ],
              ),
            );
    }
    return InkWell(
      onTap: () {
        // Navigate to full-screen image view (if necessary)
        Get.to(() => DocumentDownload(
              file: imageUrl,
            ));
      },
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: 200.0,
        fit: BoxFit.cover,
        placeholder: (context, url) => const SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => const Icon(
          Icons.error,
          size: 40,
          color: Colors.red,
        ),
      ),
    );
  }

  // Widget to show the PDF thumbnail (using PdfViewer)
  Widget _buildPdfPreview(String pdfUrl) {
    return GestureDetector(
      onTap: () async {
        // Navigate to PDF preview screen on tap
        final file = pdfUrl;
        Get.to(() => DocumentDownload(file: file));
      },
      child: Container(
        height: 200.0,
        color: Colors.grey[200],
        child: FutureBuilder(
          future: DefaultCacheManager().getSingleFile(pdfUrl),
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
  }

  // Widget for unsupported file types
  Widget _buildUnsupportedFile() {
    return const Center(
      child: Text(
        "Unsupported File Type",
        style: TextStyle(fontSize: 18, color: Colors.red),
      ),
    );
  }
}
