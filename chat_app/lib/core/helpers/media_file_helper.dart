class MediaFileHelper {
  String getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final name = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      final index = name.lastIndexOf('.');
      return index != -1 ? name.substring(index).toLowerCase() : '';
    } catch (_) {
      return '';
    }
  }

  String resolveMediaUrl(String url, String uploadType) {
    if (uploadType == 'not-upload' || uploadType == 'local') {
      return "http://52.9.12.189:4300/$url";
    }
    return "https://ciity-sms.s3.us-west-1.amazonaws.com/$url";
  }
}
