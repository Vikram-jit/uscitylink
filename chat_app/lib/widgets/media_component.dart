import 'package:chat_app/core/helpers/media_file_helper.dart';
import 'package:chat_app/widgets/file_viewer_gallery.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MediaComponent extends StatelessWidget {
  final String messageId;
  final String url;
  final String fileName;
  final String uploadType;
  final String messageDirection;
  final String? thumbnail;

  const MediaComponent({
    super.key,
    required this.messageId,
    required this.url,
    required this.fileName,
    required this.uploadType,
    required this.messageDirection,
    this.thumbnail,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = MediaFileHelper().resolveMediaUrl(url, uploadType);

    final ext = _getExt(resolvedUrl);

    if (uploadType == 'not-upload') {
      return _uploading();
    }

    if (_isImage(ext)) return _image(context, resolvedUrl);
    if (_isVideo(ext)) return _video(context);
    if (_isAudio(ext)) return _audio(context);
    if (ext == 'pdf') return _pdf(context);

    return _unknown();
  }

  // ================= NAVIGATION =================

  void _openGallery(BuildContext context) {
    Get.dialog(
      FileViewerGallery(messageId: messageId),
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
  // ================= UI =================

  Widget _image(BuildContext context, String url) {
    return GestureDetector(
      onTap: () => _openGallery(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          width: 180,
          height: 200,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _box(Icons.broken_image),
        ),
      ),
    );
  }

  Widget _video(BuildContext context) {
    return GestureDetector(
      onTap: () => _openGallery(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          (thumbnail != null && thumbnail!.isNotEmpty)
              ? Image.network(
                  thumbnail!,
                  width: 180,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _box(Icons.videocam),
                )
              : _box(Icons.videocam),

          const Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
        ],
      ),
    );
  }

  Widget _audio(BuildContext context) {
    return GestureDetector(
      onTap: () => _openGallery(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.audiotrack, color: Colors.white),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: Text(
                fileName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pdf(BuildContext context) {
    return GestureDetector(
      onTap: () => _openGallery(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
            const SizedBox(height: 6),
            SizedBox(
              width: 120,
              child: Text(
                fileName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unknown() {
    return const Text(
      "Unsupported file",
      style: TextStyle(color: Colors.white),
    );
  }

  Widget _uploading() {
    return Text(
      messageDirection == 'S' ? 'sending…' : 'receiving…',
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _box(IconData icon) {
    return Container(
      width: 180,
      height: 200,
      color: Colors.white10,
      child: Icon(icon, color: Colors.white54),
    );
  }

  // ================= HELPERS =================

  String _getExt(String url) {
    final clean = url.split('?').first;
    return clean.split('.').last.toLowerCase();
  }

  bool _isImage(String ext) =>
      ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);

  bool _isVideo(String ext) =>
      ['mp4', 'mov', 'mkv', 'webm', 'avi'].contains(ext);

  bool _isAudio(String ext) => ['mp3', 'wav', 'm4a', 'aac'].contains(ext);
}
