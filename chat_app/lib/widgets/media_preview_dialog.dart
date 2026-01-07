import 'package:chat_app/core/helpers/media_file_helper.dart';
import 'package:chat_app/widgets/pdf_preview_widget.dart';
import 'package:chat_app/widgets/video_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MediaPreviewDialog extends StatelessWidget {
  final String url;
  final String fileName;
  final String? thumbnail;

  const MediaPreviewDialog({
    super.key,
    required this.url,
    required this.fileName,
    this.thumbnail,
  });

  @override
  Widget build(BuildContext context) {
    final ext = MediaFileHelper().getFileExtension(url);

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // -------- Content --------
          Center(child: _buildPreview(ext)),

          // -------- Header --------
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- PREVIEW SWITCH ----------------

  Widget _buildPreview(String ext) {
    switch (ext) {
      // 🖼 IMAGE
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
        return InteractiveViewer(child: Image.network(url));

      // 🎥 VIDEO
      case '.mp4':
      case '.webm':
      case '.mov':
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoPlayerWidget(url: url),
        );

      // 📄 PDF
      case '.pdf':
        return PdfPreviewWidget(url: url);

      default:
        return Text(
          "Preview not supported",
          style: const TextStyle(color: Colors.white),
        );
    }
  }
}
