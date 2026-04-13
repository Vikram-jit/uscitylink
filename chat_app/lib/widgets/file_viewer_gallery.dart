import 'dart:io';
import 'dart:js_interop';

import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:web/web.dart' as web;
import 'dart:typed_data';

enum GallertType { Media, MessageFiles }

// ─────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D0D0F);
const _kSurface = Color(0xFF1E1E24);
const _kTopBar = Color(0xB8000000);
const _kBorder = Color(0x14FFFFFF);
const _kNavBg = Color(0x1AFFFFFF);
const _kNavBorder = Color(0x2EFFFFFF);
const _kText = Colors.white;
const _kTextMuted = Color(0x73FFFFFF);
const _kBtnBg = Color(0x12FFFFFF);
const _kBtnBorder = Color(0x26FFFFFF);

// ─────────────────────────────────────────────────────────────
// Gallery widget
// ─────────────────────────────────────────────────────────────

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
  final MessageController _ctrl = Get.find();
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showOverlay = true;
  bool _isSharing = false;
  bool _isDownloading = false;
  bool _isConvertDownloading = false;
  final DioClient api = DioClient();

  // Image controls
  double _imageScale = 1.0;
  int _rotationQuarter = 0; // 0=0°, 1=90°, 2=180°, 3=270°

  List<dynamic> get _files => widget.type == GallertType.MessageFiles
      ? _ctrl.messagesMedia
      : _ctrl.media;

  dynamic get _current => (_files.isEmpty || _currentIndex >= _files.length)
      ? null
      : _files[_currentIndex];

  String get _currentUrl => widget.type == GallertType.MessageFiles
      ? (_current?.url ?? '')
      : (_current?.key ?? '');

  String get _currentUploadType => widget.type == GallertType.MessageFiles
      ? (_current?.urlUploadType ?? '')
      : (_current?.uploadType ?? '');

  String get _currentFileName {
    final url = _currentUrl;
    if (url.isEmpty) return 'File';
    return url.split('/').last.split('?').first;
  }

  String get _currentFileType {
    final ext = _currentUrl.split('?').first.split('.').last.toLowerCase();
    if (_isImage(ext)) return 'Image';
    if (_isVideo(ext)) return 'Video';
    if (_isAudio(ext)) return 'Audio';
    if (ext == 'pdf') return 'PDF';
    return 'Document';
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
        backgroundColor: _kBg,
        body: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Color(0x3DFFFFFF),
            size: 56,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: GestureDetector(
        onTap: () => setState(() => _showOverlay = !_showOverlay),
        child: Stack(
          children: [
            // ── Page content ──
            PageView.builder(
              controller: _pageController,
              itemCount: _files.length,
              onPageChanged: (i) {
                if (i >= 0 && i < _files.length) {
                  setState(() {
                    _currentIndex = i;
                    _imageScale = 1.0;
                    _rotationQuarter = 0;
                  });
                }
              },
              itemBuilder: (_, i) {
                if (i < 0 || i >= _files.length) return const _BrokenFileView();
                final file = _files[i];
                final url = widget.type == GallertType.MessageFiles
                    ? file.url
                    : file.key;
                final uploadType = widget.type == GallertType.MessageFiles
                    ? file.urlUploadType
                    : file.uploadType;
                return _buildFileView(url ?? '', uploadType ?? '');
              },
            ),

            // ── Top bar ──
            AnimatedSlide(
              offset: _showOverlay ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: _showOverlay ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: _TopBar(
                  fileName: _currentFileName,
                  fileType: _currentFileType,
                  index: _currentIndex,
                  total: _files.length,
                  isSharing: _isSharing,
                  isDownloading: _isDownloading,
                  onClose: () => Get.back(),
                  onShare: _current != null ? _handleShare : null,
                  onDownload: _current != null ? _handleDownload : null,
                ),
              ),
            ),

            // ── Left / Right nav buttons (center of view) ──
            // ✅ Positioned must be a direct Stack child.
            //    AnimatedOpacity goes INSIDE the Positioned, not outside it.
            if (_files.length > 1)
              Positioned(
                top: 80,
                bottom: 56,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showOverlay ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: _NavBtn(
                          icon: Icons.chevron_left_rounded,
                          enabled: _currentIndex > 0,
                          onTap: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: _NavBtn(
                          icon: Icons.chevron_right_rounded,
                          enabled: _currentIndex < _files.length - 1,
                          onTap: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Image controls (zoom + rotate) — only for images ──
            if (_currentFileType == 'Image')
              Positioned(
                bottom: (_files.length > 1) ? 70 : 14,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showOverlay ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: _ImageControlBar(
                    onZoomIn: () => setState(
                      () => _imageScale = (_imageScale + 0.25).clamp(0.5, 5.0),
                    ),
                    onZoomOut: () => setState(
                      () => _imageScale = (_imageScale - 0.25).clamp(0.5, 5.0),
                    ),
                    onRotate: () => setState(
                      () => _rotationQuarter = (_rotationQuarter + 1) % 4,
                    ),
                    onReset: () => setState(() {
                      _imageScale = 1.0;
                      _rotationQuarter = 0;
                    }),
                    scale: _imageScale,
                    rotation: _rotationQuarter * 90,
                    onDownloadJpg: _current != null
                        ? () => _handleConvertDownload('jpg')
                        : null,
                    onDownloadPdf: _current != null
                        ? () => _handleConvertDownload('pdf')
                        : null,
                    isConverting: _isConvertDownloading,
                  ),
                ),
              ),

            // ── Bottom dots ──
            if (_files.length > 1)
              AnimatedSlide(
                offset: _showOverlay ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: _showOverlay ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: _BottomBar(
                    current: _currentIndex,
                    total: _files.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileView(String urlFile, String uploadType) {
    if (urlFile.isEmpty) return const _BrokenFileView();
    final url = resolveMediaUrl(urlFile, uploadType);
    final ext = url.split('?').first.split('.').last.toLowerCase();
    if (_isImage(ext))
      return ImageViewer(
        url: url,
        scale: _imageScale,
        rotationQuarter: _rotationQuarter,
      );
    if (_isVideo(ext)) return VideoViewer(url: url);
    if (_isAudio(ext))
      return AudioPlayerWidget(url: url, name: _current?.body ?? 'Audio');
    if (ext == 'pdf') return PdfViewerWidget(url: url);
    return UnknownFileWidget(name: _currentFileName);
  }

  bool _isImage(String ext) =>
      ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  bool _isVideo(String ext) =>
      ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  bool _isAudio(String ext) =>
      ['mp3', 'wav', 'aac', 'ogg', 'm4a'].contains(ext);

  Future<void> _handleShare() async {
    setState(() => _isSharing = true);
    try {
      final url = resolveMediaUrl(_currentUrl, _currentUploadType);
      if (GetPlatform.isWeb) {
        await Share.share(url);
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$_currentFileName';
      await Dio().download(url, path);
      await Share.shareXFiles([XFile(path)]);
    } catch (_) {
      _snack('Share failed');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _handleDownload() async {
    if (!mounted) return;
    setState(() => _isDownloading = true);
    try {
      final url = resolveMediaUrl(_currentUrl, _currentUploadType);
      if (kIsWeb) {
        final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
        anchor.href = url;
        anchor.download = _currentFileName;
        anchor.style.display = 'none';
        web.document.body?.append(anchor);
        anchor.click();
        await Future.delayed(const Duration(milliseconds: 300));
        anchor.remove();
        if (mounted) _snack('Download started');
      } else {
        final dir =
            await getDownloadsDirectory() ?? await getTemporaryDirectory();
        final path = '${dir.path}/$_currentFileName';
        await Dio().download(url, path);
        if (mounted) _snack('Saved to Downloads');
      }
    } catch (e) {
      if (mounted) _snack('Download failed');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleConvertDownload(String type) async {
    if (!mounted) return;

    setState(() => _isConvertDownloading = true);

    try {
      final fileName = _currentFileName;
      if (fileName.isEmpty) {
        if (mounted) _snack('No file name available');
        return;
      }

      final baseName = fileName.split('.').first;
      final encoded = Uri.encodeComponent(_currentUrl);
      final endpoint = type == 'jpg'
          ? '/media/convertAndDownload/$encoded'
          : '/media/convertAndDownloadPdf/$encoded';

      // Download bytes
      final response = await api.dio.get<dynamic>(
        endpoint,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data as Uint8List?;
      if (bytes == null || bytes.isEmpty) {
        if (mounted) _snack('Conversion returned empty file');
        return;
      }

      final outputName = '$baseName.$type';

      if (kIsWeb) {
        final url = createPreviewUrl(bytes);
        final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
        anchor.href = url;
        anchor.download = outputName;
        anchor.style.display = 'none';
        web.document.body!.appendChild(anchor);
        anchor.click();
        // Cleanup
        await Future.delayed(const Duration(milliseconds: 200));
        anchor.remove();
        web.URL.revokeObjectURL(url);
      } else {
        // Mobile / Desktop: request storage permission if needed
        if (Platform.isAndroid || Platform.isIOS) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            if (mounted) _snack('Storage permission required to save file');
            return;
          }
        }

        final dir =
            await getDownloadsDirectory() ?? await getTemporaryDirectory();
        final savePath = '${dir.path}/$outputName';
        await File(savePath).writeAsBytes(bytes);

        if (mounted) _snack('Saved as $outputName');
      }
    } on DioException catch (e) {
      final msg = e.response?.data != null
          ? 'Server error: ${e.response?.data}'
          : 'Convert failed: ${e.message ?? e.type.name}';
      if (mounted) _snack(msg);
    } catch (e) {
      if (mounted) _snack('Convert download failed: $e');
    } finally {
      if (mounted) setState(() => _isConvertDownloading = false);
    }
  }

  String createPreviewUrl(Uint8List bytes) {
    final blobParts = <JSAny>[bytes.toJS];
    final blob = web.Blob(blobParts.toJS);
    return web.URL.createObjectURL(blob);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(msg, style: GoogleFonts.dmSans(fontSize: 13)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top bar — file name + actions
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String fileName;
  final String fileType;
  final int index;
  final int total;
  final bool isSharing;
  final bool isDownloading;
  final VoidCallback onClose;
  final VoidCallback? onShare;
  final VoidCallback? onDownload;

  const _TopBar({
    required this.fileName,
    required this.fileType,
    required this.index,
    required this.total,
    required this.isSharing,
    required this.isDownloading,
    required this.onClose,
    this.onShare,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kTopBar,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        bottom: 12,
        left: 6,
        right: 10,
      ),
      child: Row(
        children: [
          // Close button
          _GlassIconButton(icon: Icons.close_rounded, onTap: onClose),
          const SizedBox(width: 10),

          // File icon
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _kBorder),
            ),
            child: const Icon(
              Icons.insert_drive_file_outlined,
              size: 15,
              color: _kTextMuted,
            ),
          ),
          const SizedBox(width: 10),

          // File name + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                  ),
                ),
                Text(
                  '${index + 1} of $total · $fileType',
                  style: GoogleFonts.dmSans(fontSize: 11, color: _kTextMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action buttons
          _GlassTextButton(
            icon: Icons.share_rounded,
            label: 'Share',
            loading: isSharing,
            onTap: onShare,
          ),
          const SizedBox(width: 6),
          _GlassTextButton(
            icon: Icons.download_rounded,
            label: 'Download',
            loading: isDownloading,
            onTap: onDownload,
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_NavBtn> createState() => _NavBtnState();
}

class _NavBtnState extends State<_NavBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedOpacity(
          opacity: widget.enabled ? 1.0 : 0.2,
          duration: const Duration(milliseconds: 180),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _hovered ? const Color(0x2EFFFFFF) : _kNavBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kNavBorder),
            ),
            child: Icon(widget.icon, color: _kText, size: 24),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Image control bar — zoom, rotate, download format
// ─────────────────────────────────────────────────────────────

class _ImageControlBar extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRotate;
  final VoidCallback onReset;
  final VoidCallback? onDownloadJpg;
  final VoidCallback? onDownloadPdf;
  final double scale;
  final int rotation;
  final bool isConverting;

  const _ImageControlBar({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRotate,
    required this.onReset,
    required this.scale,
    required this.rotation,
    required this.isConverting,
    this.onDownloadJpg,
    this.onDownloadPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xCC000000),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBtnBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Zoom out ──
            _CtrlBtn(
              icon: Icons.remove_rounded,
              onTap: onZoomOut,
              tooltip: 'Zoom out',
            ),
            // ── Scale label ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '${(scale * 100).round()}%',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kTextMuted,
                ),
              ),
            ),
            // ── Zoom in ──
            _CtrlBtn(
              icon: Icons.add_rounded,
              onTap: onZoomIn,
              tooltip: 'Zoom in',
            ),

            _CtrlDivider(),

            // ── Rotate ──
            _CtrlBtn(
              icon: Icons.rotate_right_rounded,
              onTap: onRotate,
              tooltip: 'Rotate 90°',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '${rotation}°',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kTextMuted,
                ),
              ),
            ),
            // ── Reset ──
            _CtrlBtn(
              icon: Icons.refresh_rounded,
              onTap: onReset,
              tooltip: 'Reset',
            ),

            _CtrlDivider(),

            // ── Download as JPG ──
            if (isConverting)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: _kText,
                  ),
                ),
              )
            else ...[
              _CtrlTextBtn(label: 'JPG', onTap: onDownloadJpg),
              const SizedBox(width: 4),
              _CtrlTextBtn(label: 'PDF', onTap: onDownloadPdf),
            ],
          ],
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _CtrlBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<_CtrlBtn> createState() => _CtrlBtnState();
}

class _CtrlBtnState extends State<_CtrlBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hovered ? const Color(0x26FFFFFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(widget.icon, color: _kText, size: 16),
          ),
        ),
      ),
    );
  }
}

class _CtrlTextBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _CtrlTextBtn({required this.label, this.onTap});

  @override
  State<_CtrlTextBtn> createState() => _CtrlTextBtnState();
}

class _CtrlTextBtnState extends State<_CtrlTextBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0x26FFFFFF) : const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: _kBtnBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.download_rounded, color: _kText, size: 11),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CtrlDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 0.5,
    height: 18,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: _kBtnBorder,
  );
}

// ─────────────────────────────────────────────────────────────
// Bottom bar — counter + dots
// ─────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int current;
  final int total;

  const _BottomBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: _kTopBar,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 12,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${current + 1} / $total',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: _kTextMuted,
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
                  width: active ? 20 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: active ? _kText : const Color(0x3DFFFFFF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Glass button components
// ─────────────────────────────────────────────────────────────

class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0x26FFFFFF) : _kBtnBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBtnBorder),
          ),
          child: Icon(widget.icon, color: _kText, size: 16),
        ),
      ),
    );
  }
}

class _GlassTextButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _GlassTextButton({
    required this.icon,
    required this.label,
    required this.loading,
    this.onTap,
  });

  @override
  State<_GlassTextButton> createState() => _GlassTextButtonState();
}

class _GlassTextButtonState extends State<_GlassTextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0x26FFFFFF) : _kBtnBg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _kBtnBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.loading
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: _kText,
                      ),
                    )
                  : Icon(widget.icon, color: _kText, size: 14),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Viewers (unchanged from original)
// ─────────────────────────────────────────────────────────────

class _BrokenFileView extends StatelessWidget {
  const _BrokenFileView();

  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(
      Icons.broken_image_outlined,
      color: Color(0x3DFFFFFF),
      size: 56,
    ),
  );
}

class ImageViewer extends StatelessWidget {
  final String url;
  final double scale;
  final int rotationQuarter;

  const ImageViewer({
    super.key,
    required this.url,
    this.scale = 1.0,
    this.rotationQuarter = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotatedBox(
        quarterTurns: rotationQuarter,
        child: Transform.scale(
          scale: scale,
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
            errorBuilder: (_, __, ___) => const _BrokenFileView(),
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
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

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
              style: GoogleFonts.dmSans(
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
                onChanged: (v) => _player.seek(_duration * v),
                activeColor: Colors.white,
                inactiveColor: Colors.white24,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmt(_position),
                  style: GoogleFonts.dmSans(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _fmt(_duration),
                  style: GoogleFonts.dmSans(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                if (_playing)
                  await _player.pause();
                else
                  await _player.play(UrlSource(widget.url));
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
    if (kIsWeb) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x26FFFFFF)),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Color(0xFFE24B4A),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'PDF Document',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Opens in a new browser tab',
              style: GoogleFonts.dmSans(
                color: const Color(0x73FFFFFF),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => web.window.open(url, '_blank'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE24B4A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.open_in_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Open PDF',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.insert_drive_file_outlined,
          color: Color(0x3DFFFFFF),
          size: 56,
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 14),
        ),
      ],
    ),
  );
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
