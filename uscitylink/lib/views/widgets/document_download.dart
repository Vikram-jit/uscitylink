import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/document_controller.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class DocumentDownload extends StatelessWidget {
  final String file; // URL of the file
  DocumentDownload({required this.file});
  final DocumentController _documentController = Get.put(DocumentController());

  @override
  Widget build(BuildContext context) {
    String extension = file.split('.').last.toLowerCase();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                // Implement download logic
                if (['png', 'jpg', 'jpeg'].contains(extension)) {
                  _documentController.saveImageToGallery(file);
                } else if (extension == 'pdf') {
                  _documentController.downloadFile(file);
                } else {
                  Get.snackbar("Error", "Unsupported file type");
                }
              },
              icon: Icon(
                Icons.download,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            IconButton(
              onPressed: () {
                _shareFile(file);
              },
              icon: Icon(
                Icons.share,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Image File Preview
              if (['png', 'jpg', 'jpeg'].contains(extension))
                _buildImagePreview(file)
              // Handle PDF File Preview
              else if (extension == 'pdf')
                _buildPdfPreview(file)
              // Handle Unsupported File Types
              else
                Center(
                    child: Text("Unsupported File Type",
                        style: TextStyle(fontSize: 18, color: Colors.red))),
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
        SnackBar(content: Text("Sharing file...")),
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
      var fileInfo = await DefaultCacheManager().getSingleFile(file);
      print('File downloaded: ${fileInfo.path}');
      ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(content: Text("File downloaded successfully!")));
    } catch (e) {
      print("Download failed: $e");
      ScaffoldMessenger.of(Get.context!)
          .showSnackBar(SnackBar(content: Text("Download failed")));
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
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: 400,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child; // Image loaded
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.error, size: 40, color: Colors.red);
        },
      ),
    );
  }

  // Widget to build the PDF preview using flutter_pdfview
  Widget _buildPdfPreview(String pdfUrl) {
    return FutureBuilder(
      future: DefaultCacheManager().getSingleFile(pdfUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading PDF'));
        } else if (snapshot.hasData) {
          // You can now use PDFView from the flutter_pdfview package
          return Container(
            width: double.infinity,
            height:
                TDeviceUtils.getScreenHeight() * 0.8, // Adjust height as needed
            child: PDFView(
              filePath: snapshot.data!.path,
              onPageChanged: (int? current, int? total) {
                print("Page $current of $total");
              },
            ),
          );
        } else {
          return Center(child: Text('No PDF data available'));
        }
      },
    );
  }
}
