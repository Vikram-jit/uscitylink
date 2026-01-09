import 'dart:io';
import 'dart:typed_data';
import 'package:chat_app/core/helpers/media_file_helper.dart';
import 'package:chat_app/widgets/dialog_toast.dart';
import 'package:chat_app/widgets/pdf_preview_widget.dart';
import 'package:chat_app/widgets/video_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: avoid_web_libraries_in_flutter

class MediaPreviewDialog extends StatefulWidget {
  final String url;
  final String fileName;
  final String? thumbnail;

  const MediaPreviewDialog({
    Key? key,
    required this.url,
    required this.fileName,
    this.thumbnail,
  }) : super(key: key);

  @override
  _MediaPreviewDialogState createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<MediaPreviewDialog> {
  late PhotoViewController _photoViewController;
  bool _isDownloading = false;
  String? _errorMessage;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _photoViewController = PhotoViewController();
    _photoViewController.outputStateStream.listen(_onScaleChanged);
  }

  void _onScaleChanged(PhotoViewControllerValue value) {
    setState(() {
      _currentScale = value.scale ?? 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ext = MediaFileHelper().getFileExtension(widget.url);

    return Dialog(
      backgroundColor: Colors.black87,
      insetPadding: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
          maxHeight: MediaQuery.of(context).size.height * 0.95,
        ),
        child: Stack(
          children: [
            // -------- Main Content --------
            _buildContent(ext),

            // -------- Header --------
            Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),

            // -------- Controls --------
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildControls(ext),
            ),

            // -------- Error Message --------
            if (_errorMessage != null)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[900],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
        child: Row(
          children: [
            // File Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getFileSizeInfo(),
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Close Button
            Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                splashRadius: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String ext) {
    if (_errorMessage != null) {
      return Center(
        child: Text(
          "Unable to load preview",
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return Center(child: _buildPreview(ext));
  }

  Widget _buildPreview(String ext) {
    switch (ext.toLowerCase()) {
      // 🖼 IMAGE with Zoom
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
      case '.bmp':
        return PhotoView(
          imageProvider: NetworkImage(widget.url),
          controller: _photoViewController,
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 3.0,
          initialScale: PhotoViewComputedScale.contained,
          backgroundDecoration: BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) => Center(
            child: Container(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: event?.expectedTotalBytes != null
                    ? (event!.cumulativeBytesLoaded / event.expectedTotalBytes!)
                    : null,
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ),
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _errorMessage = "Failed to load image";
              });
            });
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white70, size: 48),
                  SizedBox(height: 16),
                  Text(
                    "Image not available",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          },
        );

      // 🎥 VIDEO
      case '.mp4':
      case '.webm':
      case '.mov':
      case '.avi':
      case '.mkv':
        return Container(
          color: Colors.black,
          child: VideoPlayerWidget(
            url: widget.url,
            autoPlay: true,
            showControls: true,
          ),
        );

      // 📄 PDF
      case '.pdf':
        return PdfPreviewWidget(url: widget.url);

      // ❓ UNSUPPORTED
      default:
        return _buildUnsupportedPreview();
    }
  }

  Widget _buildControls(String ext) {
    final isImage = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
    ].contains(ext.toLowerCase());

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Zoom Controls (only for images)
              if (isImage) ...[
                _buildControlButton(
                  icon: Icons.zoom_out,
                  label: 'Zoom Out',
                  onPressed: () => _zoomOut(),
                ),
                _buildControlButton(
                  icon: Icons.fit_screen,
                  label: '${(_currentScale * 100).toStringAsFixed(0)}%',
                  onPressed: () => _resetZoom(),
                ),
                _buildControlButton(
                  icon: Icons.zoom_in,
                  label: 'Zoom In',
                  onPressed: () => _zoomIn(),
                ),
              ],

              // Share Button
              _buildControlButton(
                icon: Icons.share,
                label: 'Share',
                onPressed: () => _shareFile(),
              ),

              // Download Button
              _buildControlButton(
                icon: _isDownloading ? Icons.downloading : Icons.download,
                label: _isDownloading ? 'Downloading...' : 'Download',
                onPressed: _isDownloading ? null : () => _downloadFile(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: 24),
            splashRadius: 20,
            disabledColor: Colors.white30,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildUnsupportedPreview() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file, size: 80, color: Colors.white70),
            const SizedBox(height: 20),
            Text(
              widget.fileName,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Preview not available',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _downloadFile(),
              icon: Icon(Icons.download),
              label: Text('Download File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------- CONTROL METHODS --------

  void _zoomIn() {
    final newScale = (_currentScale * 1.2).clamp(0.5, 3.0);
    _photoViewController.scale = newScale;
  }

  void _zoomOut() {
    final newScale = (_currentScale / 1.2).clamp(0.5, 3.0);
    _photoViewController.scale = newScale;
  }

  void _resetZoom() {
    _photoViewController.reset();
  }

  Future<void> _downloadFile() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    try {
      if (kIsWeb) {
        // Web-specific download implementation
        await downloadFile(context);
      } else {
        // Mobile implementation
        await _downloadFileMobile();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Download failed: ${e.toString()}';
      });
      DialogToast.show(
        context: context,
        message: 'Download failed: ${e.toString()}',
        backgroundColor: Colors.red,
        icon: Icons.download,
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> downloadFile(BuildContext context) async {
    try {
      final uri = Uri.parse(widget.url);

      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!success) {
        throw Exception('Launch failed');
      }

      DialogToast.show(
        context: context,
        message: 'Download started for ${widget.fileName}',
        backgroundColor: Colors.green,
        icon: Icons.download,
      );
    } catch (e) {
      DialogToast.show(
        context: context,
        message: 'Unable to download file',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _downloadFileMobile() async {
    try {
      final response = await http.get(Uri.parse(widget.url));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final ext = MediaFileHelper().getFileExtension(widget.url);

        if (['.jpg', '.jpeg', '.png', '.gif'].contains(ext.toLowerCase())) {
          // For images - save to gallery
          final result = await ImageGallerySaver.saveImage(
            Uint8List.fromList(bytes),
            name: widget.fileName,
          );

          if (result['isSuccess']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image saved to gallery'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            throw Exception('Failed to save image');
          }
        } else {
          // For other files
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/${widget.fileName}');
          await file.writeAsBytes(bytes);

          await Share.shareXFiles([XFile(file.path)]);

          DialogToast.show(
            context: context,
            message: 'File downloaded successfully',
            backgroundColor: Colors.green,
            icon: Icons.download,
          );
        }
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _shareFile() async {
    if (kIsWeb) {
      // Web sharing using Web Share API if available
      await _shareFileWeb(context);
    } else {
      // Mobile sharing
      await _shareFileMobile();
    }
  }

  Future<void> _shareFileWeb(BuildContext context) async {
    try {
      await Share.share(widget.url, subject: widget.fileName);
    } catch (e) {
      DialogToast.show(
        context: context,
        message: 'Unable to share link',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _shareFileMobile() async {
    try {
      final response = await http.get(Uri.parse(widget.url));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${widget.fileName}');
        await file.writeAsBytes(bytes);

        await Share.shareXFiles([XFile(file.path)]);
      } else {
        throw Exception('Failed to share file');
      }
    } catch (e) {
      DialogToast.show(
        context: context,
        message: 'Share failed: ${e.toString()}',
        backgroundColor: Colors.red,
        icon: Icons.download,
      );
    }
  }

  String _getFileSizeInfo() {
    final ext = MediaFileHelper().getFileExtension(widget.url);
    return '${ext.toUpperCase().replaceFirst('.', '')} File';
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    super.dispose();
  }
}
