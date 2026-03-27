import 'dart:io' show Platform;
import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/models/message_response_model.dart';
import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

// ignore: avoid_web_libraries_in_flutter

class FileViewerGallery extends StatefulWidget {
  final String messageId;

  const FileViewerGallery({super.key, required this.messageId});

  @override
  State<FileViewerGallery> createState() => _FileViewerGalleryState();
}

class _FileViewerGalleryState extends State<FileViewerGallery> {
  final MessageController _controller = Get.find();

  late PageController _pageController;
  int _currentIndex = 0;

  bool _isSharing = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();

    final list = _controller.messagesMedia;

    _currentIndex = list.indexWhere((m) => m.id == widget.messageId);
    if (_currentIndex == -1) _currentIndex = 0;

    _pageController = PageController(initialPage: _currentIndex);
  }

  Messages get currentFile => _controller.messagesMedia[_currentIndex];

  @override
  Widget build(BuildContext context) {
    final files = _controller.messagesMedia;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: files.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (_, i) => _buildFileView(files[i]),
              ),
            ),
            _buildIndicator(files.length),
          ],
        ),
      ),
    );
  }

  // ================= UI =================

  Widget _buildTopBar() {
    final file = currentFile;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.black.withOpacity(0.7),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          Expanded(
            child: Text(
              file.body ?? "File",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          _iconBtn(Icons.share, () => _shareFile(file), _isSharing),
          _iconBtn(Icons.download, () => _downloadFile(file), _isDownloading),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, bool loading) {
    return IconButton(
      onPressed: loading ? null : onTap,
      icon: loading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, color: Colors.white),
    );
  }

  Widget _buildIndicator(int length) {
    if (length <= 1) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        "${_currentIndex + 1} / $length",
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildFileView(Messages file) {
    final url = resolveMediaUrl(file.url ?? "", file.urlUploadType ?? "");

    if (file.isImage) return ImageViewer(url: url);
    if (file.isVideo) return VideoViewer(url: url);
    if (file.isAudio)
      return AudioPlayerWidget(url: url, name: file.body ?? "Audio");
    if (file.isPdf) return PdfViewerWidget(url: url);

    return UnknownFileWidget(name: file.body ?? "File");
  }

  // ================= ACTIONS =================

  Future<void> _shareFile(Messages file) async {
    try {
      setState(() => _isSharing = true);

      final url = resolveMediaUrl(file.url ?? "", file.urlUploadType ?? "");

      if (GetPlatform.isWeb) {
        await Share.share(url);
        return;
      }

      final dir = await getTemporaryDirectory();
      final path = "${dir.path}/${file.body ?? 'file'}";

      await Dio().download(url, path);
      await Share.shareXFiles([XFile(path)]);
    } catch (e) {
      _snack("Share failed");
    } finally {
      setState(() => _isSharing = false);
    }
  }

  Future<void> _downloadFile(Messages file) async {
    try {
      setState(() => _isDownloading = true);

      final url = resolveMediaUrl(file.url ?? "", file.urlUploadType ?? "");

      // if (GetPlatform.isWeb) {
      //   final anchor = html.AnchorElement(href: url)
      //     ..setAttribute("download", file.body ?? "file")
      //     ..click();

      //   _snack("Download started");
      //   return;
      // }

      final dir =
          await getDownloadsDirectory() ?? await getTemporaryDirectory();

      final path = "${dir.path}/${file.body ?? 'file'}";

      await Dio().download(url, path);

      _snack("Saved to ${dir.path}");
    } catch (e) {
      _snack("Download failed");
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.primary, content: Text(msg)),
    );
  }
}

// ================= VIEWERS =================

class ImageViewer extends StatelessWidget {
  final String url;
  const ImageViewer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
    );
  }
}

class VideoViewer extends StatefulWidget {
  final String url;
  const VideoViewer({super.key, required this.url});

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            GestureDetector(
              onTap: () {
                setState(() {
                  controller.value.isPlaying
                      ? controller.pause()
                      : controller.play();
                });
              },
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final String name;

  const AudioPlayerWidget({super.key, required this.url, required this.name});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final player = AudioPlayer();
  bool playing = false;

  void toggle() async {
    if (playing) {
      await player.pause();
    } else {
      await player.play(UrlSource(widget.url));
    }
    setState(() => playing = !playing);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              playing ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: toggle,
          ),
          Text(widget.name, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class PdfViewerWidget extends StatelessWidget {
  final String url;
  const PdfViewerWidget({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    if (GetPlatform.isWeb) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: () {
            //html.window.open(url, "_blank");
          },
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text("Open PDF"),
        ),
      );
    }

    return SfPdfViewer.network(url);
  }
}

class UnknownFileWidget extends StatelessWidget {
  final String name;
  const UnknownFileWidget({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(name, style: const TextStyle(color: Colors.white)),
    );
  }
}

// ================= URL =================

String resolveMediaUrl(String url, String uploadType) {
  if (url.startsWith("http")) return url;

  if (uploadType == 'not-upload' || uploadType == 'local') {
    return "http://52.9.12.189:4300/$url";
  }

  return "https://ciity-sms.s3.us-west-1.amazonaws.com/$url";
}
