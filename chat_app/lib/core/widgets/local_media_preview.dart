import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;

class LocalMediaPreview extends StatelessWidget {
  final PlatformFile platformFile;
  final double width;
  final double height;
  final VoidCallback? onRemove;

  const LocalMediaPreview({
    super.key,
    required this.platformFile,
    this.width = 180,
    this.height = 200,
    this.onRemove,
  });

  String get _name => platformFile.name;
  String get _ext => p.extension(_name).replaceFirst('.', '').toLowerCase();
  Uint8List? get _bytes => platformFile.bytes;
  String? get _path => platformFile.path;

  bool get _isImage => ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(_ext);
  bool get _isVideo => ['mp4', 'mov', 'mkv', 'webm', 'avi'].contains(_ext);
  bool get _isAudio => ['mp3', 'wav', 'm4a', 'aac', 'ogg'].contains(_ext);
  bool get _isPdf => _ext == 'pdf';

  ImageProvider? get _imageProvider {
    if (kIsWeb) return _bytes != null ? MemoryImage(_bytes!) : null;
    if (_path != null) return FileImage(File(_path!));
    if (_bytes != null) return MemoryImage(_bytes!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder resolves double.infinity into a real pixel width.
    // In release mode Flutter is strict — passing infinity directly to
    // Image/Container width causes a hard crash. This fixes it.
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth =
            (width == double.infinity || width.isInfinite || width.isNaN)
            ? constraints.maxWidth.isInfinite
                  ? 300.0 // absolute fallback if parent is also unbounded
                  : constraints.maxWidth
            : width;

        Widget content = _buildContent(resolvedWidth);

        if (onRemove != null) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              content,
              Positioned(
                top: -6,
                right: -6,
                child: _DismissButton(onTap: onRemove!),
              ),
            ],
          );
        }

        return content;
      },
    );
  }

  Widget _buildContent(double resolvedWidth) {
    if (_isImage) {
      final provider = _imageProvider;
      return provider != null
          ? _ImagePreview(
              provider: provider,
              width: resolvedWidth,
              height: height,
            )
          : _MediaBox(
              width: resolvedWidth,
              height: height,
              icon: Icons.image_outlined,
            );
    }

    if (_isVideo) return _VideoPreview(width: resolvedWidth, height: height);
    if (_isAudio) return _AudioPreview(name: _name, width: resolvedWidth);
    if (_isPdf) return _PdfPreview(name: _name, width: resolvedWidth);

    return _GenericFilePreview(name: _name, ext: _ext, width: resolvedWidth);
  }
}

// ─────────────────────────────────────────────────────────────
// Image
// ─────────────────────────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  final ImageProvider provider;
  final double width;
  final double height;

  const _ImagePreview({
    required this.provider,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image(
        image: provider,
        width: width,
        height: height,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _MediaBox(
          width: width,
          height: height,
          icon: Icons.broken_image_outlined,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Video
// ─────────────────────────────────────────────────────────────

class _VideoPreview extends StatelessWidget {
  final double width;
  final double height;

  const _VideoPreview({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _MediaBox(width: width, height: height, icon: Icons.videocam_outlined),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Audio
// ─────────────────────────────────────────────────────────────

class _AudioPreview extends StatelessWidget {
  final String name;
  final double width;

  const _AudioPreview({required this.name, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB8BFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF6C3FC4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1730),
                  ),
                ),
                Text(
                  'Audio file',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF9B97A8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PDF
// ─────────────────────────────────────────────────────────────

class _PdfPreview extends StatelessWidget {
  final String name;
  final double width;

  const _PdfPreview({required this.name, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF09595)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE24B4A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF791F1F),
                  ),
                ),
                Text(
                  'PDF document',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFFA32D2D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Generic
// ─────────────────────────────────────────────────────────────

class _GenericFilePreview extends StatelessWidget {
  final String name;
  final String ext;
  final double width;

  const _GenericFilePreview({
    required this.name,
    required this.ext,
    required this.width,
  });

  Color get _accentBg => switch (ext) {
    'doc' || 'docx' => const Color(0xFFE6F1FB),
    'xls' || 'xlsx' || 'csv' => const Color(0xFFEAF3DE),
    'zip' || 'rar' || '7z' => const Color(0xFFFAEEDA),
    _ => const Color(0xFFF1EFE8),
  };

  Color get _iconBg => switch (ext) {
    'doc' || 'docx' => const Color(0xFF185FA5),
    'xls' || 'xlsx' || 'csv' => const Color(0xFF3B6D11),
    'zip' || 'rar' || '7z' => const Color(0xFFBA7517),
    _ => const Color(0xFF5F5E5A),
  };

  Color get _textColor => switch (ext) {
    'doc' || 'docx' => const Color(0xFF042C53),
    'xls' || 'xlsx' || 'csv' => const Color(0xFF173404),
    'zip' || 'rar' || '7z' => const Color(0xFF412402),
    _ => const Color(0xFF2C2C2A),
  };

  IconData get _icon => switch (ext) {
    'doc' || 'docx' => Icons.description_rounded,
    'xls' || 'xlsx' || 'csv' => Icons.table_chart_rounded,
    'zip' || 'rar' || '7z' => Icons.folder_zip_rounded,
    'txt' || 'md' => Icons.text_snippet_rounded,
    _ => Icons.insert_drive_file_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _accentBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _iconBg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                  ),
                ),
                Text(
                  ext.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: _textColor.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Fallback box
// ─────────────────────────────────────────────────────────────

class _MediaBox extends StatelessWidget {
  final IconData icon;
  final double width;
  final double height;

  const _MediaBox({
    required this.icon,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFE8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: const Color(0xFF888780), size: 32),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dismiss button
// ─────────────────────────────────────────────────────────────

class _DismissButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DismissButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1730),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
      ),
    );
  }
}
