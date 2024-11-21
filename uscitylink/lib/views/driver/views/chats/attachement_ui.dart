import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:pdf_render/pdf_render_widgets.dart';
import 'package:uscitylink/views/widgets/document_download.dart';

class AttachementUi extends StatelessWidget {
  final String fileUrl; // URL of the file to preview
  final controller = PdfViewerController();

  AttachementUi({super.key, required this.fileUrl});

  @override
  Widget build(BuildContext context) {
    // Extract file extension (lowercase for consistency)
    String extension = fileUrl.split('.').last.toLowerCase();

    // Check for file extension and display corresponding preview
    if (['png', 'jpg', 'jpeg'].contains(extension)) {
      // Image files (PNG, JPG, JPEG)
      return _buildImagePreview(fileUrl);
    } else if (extension == 'pdf') {
      // PDF file
      return _buildPdfPreview(fileUrl);
    } else {
      // Unknown or unsupported file type
      return _buildUnsupportedFile();
    }
  }

  // Widget to show the image preview (network image)
  Widget _buildImagePreview(String imageUrl) {
    return InkWell(
      onTap: () {
        // Navigate to full-screen image view (if necessary)
        Get.to(() => DocumentDownload(
              file: imageUrl,
            ));
      },
      child: Image.network(
        imageUrl,
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
