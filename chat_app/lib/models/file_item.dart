class FileItem {
  final String url;
  final String name;
  final String extension;

  const FileItem({
    required this.url,
    required this.name,
    required this.extension,
  });

  String get extLower => extension.toLowerCase();

  bool get isImage =>
      extLower == 'jpg' ||
      extLower == 'jpeg' ||
      extLower == 'png' ||
      extLower == 'webp';

  bool get isVideo =>
      extLower == 'mp4' ||
      extLower == 'mov' ||
      extLower == 'mkv';

  bool get isAudio =>
      extLower == 'mp3' ||
      extLower == 'wav' ||
      extLower == 'm4a';

  bool get isPdf => extLower == 'pdf';
}

