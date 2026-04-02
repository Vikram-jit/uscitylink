import 'dart:io';
import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/models/message_response_model.dart';
import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:web/web.dart' as web; // Modern 2026 standard for Web/Wasm

enum GallertType { Media, MessageFiles }

class FileViewerGallery extends StatefulWidget {
  final String messageId;
  final int initialIndex;
  final GallertType type;

  const FileViewerGallery({
    super.key,
    required this.messageId,
    this.initialIndex = 0,
    this.type = GallertType.MessageFiles,
  });

  @override
  State<FileViewerGallery> createState() => _FileViewerGalleryState();
}

class _FileViewerGalleryState extends State<FileViewerGallery> {
  final MessageController _controller = Get.find();
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showOverlay = true;
  bool _isSharing = false;
  bool _isDownloading = false;

  // ── Safe list getter ──
  List<dynamic> get _files => widget.type == GallertType.MessageFiles
      ? _controller.messagesMedia
      : _controller.media;

  dynamic get _currentItem {
    if (_files.isEmpty || _currentIndex >= _files.length) return null;
    return _files[_currentIndex];
  }

  @override
  void initState() {
    super.initState();

    if (widget.type == GallertType.MessageFiles) {
      final idx = _files.indexWhere((m) => m.id == widget.messageId);
      _currentIndex = idx == -1 ? 0 : idx;
    } else {
      _currentIndex = widget.initialIndex.clamp(
        0,
        _files.isEmpty ? 0 : _files.length - 1,
      );
    }

    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_files.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.white24,
            size: 56,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showOverlay = !_showOverlay),
        child: Stack(
          children: [
            // ── Page viewer ──
            PageView.builder(
              controller: _pageController,
              itemCount: _files.length,
              onPageChanged: (i) {
                if (i >= 0 && i < _files.length) {
                  setState(() => _currentIndex = i);
                }
              },
              itemBuilder: (_, i) {
                if (i < 0 || i >= _files.length) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white24,
                      size: 56,
                    ),
                  );
                }
                final file = _files[i];
                return _buildFileView(
                  widget.type == GallertType.MessageFiles ? file.url : file.key,
                  widget.type == GallertType.MessageFiles
                      ? file.urlUploadType
                      : file.uploadType,
                );
              },
            ),

            // ── Top bar ──
            AnimatedSlide(
              offset: _showOverlay ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: _showOverlay ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: _TopBar(
                  item: _currentItem,
                  isSharing: _isSharing,
                  isDownloading: _isDownloading,
                  onClose: () => Get.back(),
                  onShare: _currentItem != null
                      ? () => _shareFile(
                          widget.type == GallertType.MessageFiles
                              ? _currentItem.url
                              : _currentItem.key,
                          widget.type == GallertType.MessageFiles
                              ? _currentItem.urlUploadType
                              : _currentItem.uploadType,
                        )
                      : null,
                  onDownload: _currentItem != null
                      ? () => _downloadFile(
                          widget.type == GallertType.MessageFiles
                              ? _currentItem.url
                              : _currentItem.key,
                          widget.type == GallertType.MessageFiles
                              ? _currentItem.urlUploadType
                              : _currentItem.uploadType,
                        )
                      : null,
                ),
              ),
            ),

            // ── Bottom indicator ──
            if (_files.length > 1)
              AnimatedSlide(
                offset: _showOverlay ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: _showOverlay ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: _BottomIndicator(
                    current: _currentIndex,
                    total: _files.length,
                    onPrev: _currentIndex > 0
                        ? () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                        : null,
                    onNext: _currentIndex < _files.length - 1
                        ? () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── File view builder ──
  Widget _buildFileView(String urlFile, String uploadType) {
    if (urlFile.isEmpty) {
      return const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.white24,
          size: 56,
        ),
      );
    }

    final url = resolveMediaUrl(urlFile, uploadType);
    final ext = url.split('?').first.split('.').last.toLowerCase();

    if (_isImage(ext)) return ImageViewer(url: url);
    if (_isVideo(ext)) return VideoViewer(url: url);
    if (_isAudio(ext)) {
      return AudioPlayerWidget(url: url, name: _currentItem?.body ?? 'Audio');
    }
    if (ext == 'pdf') return PdfViewerWidget(url: url);

    return UnknownFileWidget(name: 'File');
  }

  bool _isImage(String ext) =>
      ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  bool _isVideo(String ext) =>
      ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  bool _isAudio(String ext) =>
      ['mp3', 'wav', 'aac', 'ogg', 'm4a'].contains(ext);

  // ── Actions ──
  Future<void> _shareFile(String file, String urlUploadType) async {
    setState(() => _isSharing = true);
    try {
      final url = resolveMediaUrl(file, urlUploadType);
      if (GetPlatform.isWeb) {
        await Share.share(url);
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/${file}';
      await Dio().download(url, path);
      await Share.shareXFiles([XFile(path)]);
    } catch (_) {
      _snack('Share failed');
    } finally {
      setState(() => _isSharing = false);
    }
  }

  Future<void> _downloadFile(String file, String urlUploadType) async {
    setState(() => _isDownloading = true);
    try {
      final url = resolveMediaUrl(file, urlUploadType);
      if (kIsWeb) {
        final anchor = web.document.createElement('a') as dynamic;

        anchor.href = url;
        anchor.download = file;
        anchor.style.display = 'none';

        web.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
        return;
      }
      final dir =
          await getDownloadsDirectory() ?? await getTemporaryDirectory();
      final path = '${dir.path}/${file}';
      await Dio().download(url, path);
      _snack('Saved to Downloads');
    } catch (_) {
      _snack('Download failed');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final dynamic? item;
  final bool isSharing;
  final bool isDownloading;
  final VoidCallback onClose;
  final VoidCallback? onShare;
  final VoidCallback? onDownload;

  const _TopBar({
    required this.item,
    required this.isSharing,
    required this.isDownloading,
    required this.onClose,
    this.onShare,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        bottom: 20,
        left: 4,
        right: 8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: onClose,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'File',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                // if (item?.createdAt != null)
                //   Text(
                //     _formatDate(item!.createdAt!),
                //     style: GoogleFonts.poppins(
                //       color: Colors.white54,
                //       fontSize: 11,
                //     ),
                //   ),
              ],
            ),
          ),
          _ActionBtn(
            icon: Icons.share_rounded,
            loading: isSharing,
            onTap: onShare,
          ),
          _ActionBtn(
            icon: Icons.download_rounded,
            loading: isDownloading,
            onTap: onDownload,
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}  '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final bool loading;
  final VoidCallback? onTap;

  const _ActionBtn({required this.icon, required this.loading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: loading ? null : onTap,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, color: Colors.white, size: 22),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom indicator
// ─────────────────────────────────────────────────────────────

class _BottomIndicator extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _BottomIndicator({
    required this.current,
    required this.total,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 24,
          left: 16,
          right: 16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Prev button
            _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),

            // Counter + dots
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${current + 1} / $total',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(total.clamp(0, 10), (i) {
                    final active = i == current % 10;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white30,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ),

            // Next button
            _NavBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap != null ? 1.0 : 0.2,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Viewers
// ─────────────────────────────────────────────────────────────

class ImageViewer extends StatelessWidget {
  final String url;
  const ImageViewer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                color: Colors.white54,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white24,
              size: 56,
            ),
          ),
        ),
      ),
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
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            GestureDetector(
              onTap: () => setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              }),
              child: AnimatedOpacity(
                opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white12,
                ),
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
  final _player = AudioPlayer();
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((d) => setState(() => _position = d));
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPlayerComplete.listen((_) => setState(() => _playing = false));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:'
      '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.audiotrack_rounded,
              color: Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              widget.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: SliderComponentShape.noOverlay,
                trackHeight: 3,
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (v) {
                  final pos = _duration * v;
                  _player.seek(pos);
                },
                activeColor: Colors.white,
                inactiveColor: Colors.white24,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(_position),
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _fmt(_duration),
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                if (_playing) {
                  await _player.pause();
                } else {
                  await _player.play(UrlSource(widget.url));
                }
                setState(() => _playing = !_playing);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
          onPressed: () {},
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: Text(
            'Open PDF',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            color: Colors.white24,
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// URL resolver
// ─────────────────────────────────────────────────────────────

String resolveMediaUrl(String url, String uploadType) {
  if (url.startsWith('http')) return url;
  if (uploadType == 'not-upload' || uploadType == 'local') {
    return 'http://52.9.12.189:4300/$url';
  }
  return 'https://ciity-sms.s3.us-west-1.amazonaws.com/$url';
}
