import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart'; // for better video controls

class MediaComponent extends StatelessWidget {
  final String url;
  final String? name;
  final String? fileName;
  final String? type;
  final String? thumbnail;
  final DateTime? dateTime;
  final double width;
  final double height;
  final VoidCallback? onClick;

  const MediaComponent({
    super.key,
    required this.url,
    this.name,
    this.fileName,
    this.type,
    this.thumbnail,
    this.dateTime,
    this.width = 180,
    this.height = 200,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final ext = _getExtension(url);

    /// ------------------ VIDEO ------------------
    if (_videoExt.contains(ext)) {
      return InkWell(
        onTap: () => _openDialog(context, type: "video"),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              thumbnail ?? url,
              width: width,
              height: height,
              fit: BoxFit.cover,
            ),
            const Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
          ],
        ),
      );
    }

    /// ------------------ AUDIO ------------------
    if (_audioExt.contains(ext)) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(Icons.audiotrack_rounded, size: 45, color: Colors.blueGrey),
            Text(fileName ?? "Audio", overflow: TextOverflow.ellipsis),
            ElevatedButton(
              onPressed: () => _openDialog(context, type: "audio"),
              child: const Text("Play"),
            ),
          ],
        ),
      );
    }

    /// ------------------ IMAGES ------------------
    if (_imageExt.contains(ext)) {
      return InkWell(
        onTap: onClick,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: width,
            height: height,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    /// ------------------ PDF ------------------
    if (ext == ".pdf") {
      return InkWell(
        onTap: () => _openDialog(context, type: "pdf"),
        child: Column(
          children: [
            const Icon(Icons.picture_as_pdf, size: 50, color: Colors.red),
            Text(fileName ?? "PDF Document"),
          ],
        ),
      );
    }

    /// ------------------ DEFAULT ------------------
    return Text("Unsupported file: $ext");
  }

  // -------------------- Helper Methods --------------------
  String _getExtension(String url) {
    final uri = Uri.parse(url);
    final path = uri.path;
    return ".${path.split('.').last.toLowerCase()}";
  }

  void _openDialog(BuildContext context, {required String type}) {
    showDialog(
      context: context,
      builder: (_) =>
          Dialog(backgroundColor: Colors.black, child: _buildViewer(type)),
    );
  }

  Widget _buildViewer(String type) {
    if (type == "video") {
      return Chewie(
        controller: ChewieController(
          videoPlayerController: VideoPlayerController.network(url),
          autoPlay: true,
          looping: false,
        ),
      );
    }

    if (type == "audio") {
      return Center(
        child: Icon(Icons.audiotrack, size: 80, color: Colors.white),
      );
    }

    if (type == "pdf") {
      return Center(
        child: Text(
          "Open PDF Viewer Here",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return const SizedBox();
  }
}

// ------------------- File Extension Groups -------------------
const _videoExt = [".mp4", ".mkv", ".avi", ".mov", ".flv", ".webm"];
const _audioExt = [".mp3", ".aac", ".m4a", ".wav", ".ogg", ".flac"];
const _imageExt = [".jpg", ".jpeg", ".png", ".gif", ".webp"];
