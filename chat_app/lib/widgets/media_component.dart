import 'package:chat_app/core/helpers/media_file_helper.dart';
import 'package:chat_app/widgets/media_preview_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MediaComponent extends StatelessWidget {
  final String url;
  final String fileName;
  final String uploadType; // not-upload | local | server
  final String messageDirection; // S | R
  final String? thumbnail;

  const MediaComponent({
    super.key,
    required this.url,
    required this.fileName,
    required this.uploadType,
    required this.messageDirection,
    this.thumbnail,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = MediaFileHelper().resolveMediaUrl(url, uploadType);
    final ext = MediaFileHelper().getFileExtension(resolvedUrl);

    switch (ext) {
      // ---------------- VIDEO ----------------
      case '.mp4':
      case '.mkv':
      case '.avi':
      case '.mov':
      case '.webm':
        return _video(resolvedUrl, context);

      // ---------------- AUDIO ----------------
      case '.mp3':
      case '.wav':
      case '.aac':
      case '.m4a':
        return _audio(resolvedUrl);

      // ---------------- IMAGE ----------------
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
        return _image(resolvedUrl, context);

      // ---------------- PDF ----------------
      case '.pdf':
        return _pdf(context);

      default:
        return Text(resolvedUrl, style: const TextStyle(fontSize: 12));
    }
  }

  // ================= UI BUILDERS =================

  Widget _image(String url, BuildContext context) {
    if (uploadType == 'not-upload') {
      return _uploading();
    }

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => MediaPreviewDialog(
            url: url,
            fileName: fileName,
            thumbnail: thumbnail ?? "-",
          ),
        );
      },
      child: Image.network(url, width: 180, height: 200, fit: BoxFit.contain),
    );
  }

  Widget _video(String url, BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => MediaPreviewDialog(
            url: url,
            fileName: fileName,
            thumbnail: thumbnail ?? "-",
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            thumbnail ?? '',
            width: 180,
            height: 200,
            fit: BoxFit.contain,
          ),
          const Icon(Icons.play_circle_fill, size: 52, color: Colors.white),
        ],
      ),
    );
  }

  Widget _audio(String url) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.audiotrack),
        const SizedBox(width: 6),
        Text(fileName, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }

  Widget _pdf(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => MediaPreviewDialog(
            url: url,
            fileName: fileName,
            thumbnail: thumbnail ?? "-",
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf, size: 44, color: Colors.red),
          Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _uploading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          messageDirection == 'S' ? Icons.upload : Icons.download,
          size: 28,
          color: Colors.grey,
        ),
        const SizedBox(height: 4),
        Text(
          messageDirection == 'S' ? 'sending…' : 'receiving…',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
