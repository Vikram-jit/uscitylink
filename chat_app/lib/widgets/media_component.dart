import 'package:chat_app/core/helpers/media_file_helper.dart';
import 'package:chat_app/widgets/file_viewer_gallery.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MediaComponent extends StatelessWidget {
  final String messageId;
  final String url;
  final String fileName;
  final String uploadType;
  final String messageDirection;
  final GallertType type;
  final String? thumbnail;
  final int? initialIndex;
  final bool? isGalleryBool;
  final String createdAt;

  const MediaComponent({
    super.key,
    required this.messageId,
    required this.url,
    required this.fileName,
    required this.uploadType,
    required this.messageDirection,
    required this.type,
    this.thumbnail,
    this.initialIndex,
    this.isGalleryBool = true,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = MediaFileHelper().resolveMediaUrl(url, uploadType);
    final ext = _getExt(resolvedUrl);

    if (uploadType == 'not-upload') {
      return _uploading();
    }

    if (_isImage(ext)) return _tile(context, _imageContent(resolvedUrl));
    if (_isVideo(ext)) return _tile(context, _videoContent());
    if (_isAudio(ext)) return _tile(context, _audioContent());
    if (ext == 'pdf') return _tile(context, _pdfContent());

    return _unknown();
  }

  // ================= SHARED TILE WRAPPER =================

  // LayoutBuilder decides actual size:
  //   • In a SliverGrid the height IS bounded  → use cell dimensions
  //   • In a Column the height is NOT bounded  → use fixed 180 × 200
  Widget _tile(BuildContext context, Widget content) {
    return GestureDetector(
      onTap: () => _openGallery(context),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final inGrid = constraints.hasBoundedHeight;
          final double w = inGrid ? constraints.maxWidth : 180;
          final double h = inGrid ? constraints.maxHeight : 200;
          return SizedBox(
            width: w,
            height: h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [content, _timestampOverlay()],
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= NAVIGATION =================

  void _openGallery(BuildContext context) {
    if (isGalleryBool == true) {
      Get.dialog(
        FileViewerGallery(
          messageId: messageId,
          initialIndex: initialIndex ?? 0,
          type: type,
        ),
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        transitionDuration: const Duration(milliseconds: 250),
      );
    }
  }

  // ================= CONTENT WIDGETS =================

  Widget _imageContent(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image),
    );
  }

  Widget _videoContent() {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        (thumbnail != null && thumbnail!.isNotEmpty)
            ? Image.network(
                thumbnail!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(Icons.videocam),
              )
            : _placeholder(Icons.videocam),
        const Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
      ],
    );
  }

  Widget _audioContent() {
    return ColoredBox(
      color: Colors.white10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.audiotrack, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
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

  Widget _pdfContent() {
    return ColoredBox(
      color: const Color(0x33F44336), // red 20%
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ================= OVERLAY =================

  Widget _timestampOverlay() {
    final label = _formatCreatedAt();
    if (label.isEmpty) return const SizedBox.shrink();
    return Positioned(
      bottom: 6,
      right: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            letterSpacing: 0.2,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ================= MISC =================

  Widget _unknown() {
    return const Text(
      'Unsupported file',
      style: TextStyle(color: Colors.white),
    );
  }

  Widget _uploading() {
    return Text(
      messageDirection == 'S' ? 'sending…' : 'receiving…',
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _placeholder(IconData icon) {
    return ColoredBox(
      color: Colors.white10,
      child: Center(child: Icon(icon, color: Colors.white54)),
    );
  }

  String _formatCreatedAt() {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      return '${DateFormat('MM/dd/yyyy h:mm a').format(dt)}';
    } catch (_) {
      return '';
    }
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
