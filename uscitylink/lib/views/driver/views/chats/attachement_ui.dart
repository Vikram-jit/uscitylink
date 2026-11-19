import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/utils/constant/colors.dart';
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
  final String messageId;
  AttachementUi(
      {super.key,
      required this.fileUrl,
      required this.directionType,
      this.thumbnail = "",
      this.url_upload_type = "server",
      this.direction = false,
      this.location = "driver",
      this.localFilePath = "",
      this.messageId = ""});

  @override
  State<AttachementUi> createState() => _AttachementUiState();
}

class _AttachementUiState extends State<AttachementUi> {
  // URL of the file to preview
  // final controller = PdfViewerController();

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
  bool get _hasLocalFile =>
      widget.localFilePath.isNotEmpty && File(widget.localFilePath).existsSync();

  @override
  Widget build(BuildContext context) {
    // Extract file extension (lowercase for consistency)
    String extension = widget.fileUrl.split('.').last.toLowerCase();

    // Check for file extension and display corresponding preview
    if (['png', 'jpg', 'jpeg'].contains(extension)) {
      // Image files (PNG, JPG, JPEG)
      return _buildImagePreview(widget.fileUrl, widget.url_upload_type);
    }
    // Not in S3 yet: open the API server's copy
    final notInS3 = widget.url_upload_type == "not-upload" ||
        widget.url_upload_type == "failed";
    final fileUrl = notInS3 ? serverFileUrl(widget.fileUrl) : widget.fileUrl;
    final thumbnail = notInS3 ? serverFileUrl(widget.thumbnail) : widget.thumbnail;
    if (extension == 'pdf') {
      // PDF file
      return _buildPdfPreview(fileUrl);
    } else if (videoExtensions.contains(extension)) {
      return _buildVideoPreview(fileUrl, thumbnail);
    } else if (isSupportedFormat(fileUrl)) {
      return AudioPlayerWidget(audioUrl: fileUrl);
      // return Center(
      //   child: Text("Audio Player Unavailable"),
      // );
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
                          color: TColors.navyHeader,
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
                Icons.play_circle_fill_rounded,
                color: Colors.white.withOpacity(0.9),
                size: 46,
              ))
            ],
          ),
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
    if (url_upload_type == "failed" && _hasLocalFile) {
      return Image.file(File(widget.localFilePath),
          width: double.infinity,
          height: 300.0,
          fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
        print(error.toString());
        return const Icon(
          Icons.error,
          size: 40,
          color: Colors.red,
        );
      });
    }
    if (url_upload_type == "local-file") {
      return Image.file(File(widget.localFilePath),
          width: double.infinity,
          height: 200.0,
          fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.error,
          size: 40,
          color: Colors.red,
        );
      });
    }
    if (url_upload_type == "queue") {
      return Image.file(File(widget.localFilePath),
          width: double.infinity,
          height: 200.0,
          fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.error,
          size: 40,
          color: Colors.red,
        );
      });
    }
    // Not in S3 yet (or the copy to S3 failed): the file is already on the API server, so show it from
    // there instead of a spinner that never ends. If the server copy is gone (S3 got it meanwhile), use S3.
    if ((url_upload_type == "not-upload" || url_upload_type == "failed") &&
        serverFileUrl(imageUrl) != imageUrl) {
      final onServer = serverFileUrl(imageUrl);
      final sending = (widget.location == "driver" && widget.directionType == "R") ||
          (widget.location == "staff" && widget.directionType == "S");
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(() => DocumentDownload(file: onServer)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: onServer,
                width: double.infinity,
                height: 200.0,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: TColors.navyHeader),
                  ),
                ),
                errorWidget: (context, url, error) => CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 200.0,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
              ),
              if (sending && url_upload_type == "not-upload")
                const Positioned(
                  right: 8,
                  top: 8,
                  child: Icon(Icons.cloud_upload_rounded,
                      size: 20, color: Colors.white),
                ),
            ],
          ),
        ),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // Navigate to full-screen image view (if necessary)
        Get.to(() => DocumentDownload(
              file: imageUrl,
            ));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: 200.0,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: TColors.navyHeader),
            ),
          ),
          errorWidget: (context, url, error) => const Icon(
            Icons.error,
            size: 40,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildPdfPreview(String pdfUrl) {
    return GestureDetector(
      onTap: () async {
        Get.to(() => DocumentDownload(file: pdfUrl));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: FutureBuilder<File?>(
          future: DefaultCacheManager().getSingleFile(pdfUrl),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: TColors.navyHeader));
            } else if (snapshot.hasError) {
              return const Center(
                child: Icon(Icons.error, size: 40, color: Colors.red),
              );
            } else if (snapshot.hasData && snapshot.data != null) {
              final file = snapshot.data!;
              return FutureBuilder<PdfDocument?>(
                future: PdfDocument.openFile(file.path),
                builder: (context, pdfSnapshot) {
                  if (pdfSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: TColors.navyHeader));
                  } else if (pdfSnapshot.hasError) {
                    return const Center(
                      child: Icon(Icons.error, size: 40, color: Colors.red),
                    );
                  } else if (pdfSnapshot.hasData) {
                    return PdfPageView(
                      document: pdfSnapshot.data!,
                      pageNumber: 1,
                    );
                  } else {
                    return const Center(child: Text('Failed to load PDF'));
                  }
                },
              );
            } else {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No PDF available',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
          },
        ),
        ),
      ),
    );
  }

  // Widget for unsupported file types
  Widget _buildUnsupportedFile() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined,
                size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              "Unsupported file type",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// The API server's copy of a chat file (it keeps it until the copy to S3 is done):
/// https://ciity-sms…/uscitylink/x.jpg → https://<api server>/uscitylink/x.jpg. Other links are returned as they are.
String serverFileUrl(String url) {
  final s3 = "${Constant.aws}/";
  if (!url.startsWith(s3)) return url;
  return "${Constant.tempImageUrl}${url.substring(s3.length)}";
}
