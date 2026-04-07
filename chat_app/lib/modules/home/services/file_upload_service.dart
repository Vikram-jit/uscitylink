import 'package:chat_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class FileUploadResult {
  final bool status;
  final String? key;
  final String? thumbnail;
  final String message;

  FileUploadResult({
    required this.status,
    this.key,
    this.thumbnail,
    required this.message,
  });
}

class FileUploadService {
  final DioClient api = DioClient();

  final List<String> _videoExtensions = const [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'flv',
    'webm',
    'mpeg',
    'mpg',
    'wmv',
  ];

  Future<FileUploadResult> uploadForUserMessage({
    required PlatformFile file,
    required String userId,
    String? groupId,
  }) async {
    try {
      final ext = (file.extension ?? "").toLowerCase().trim();

      final isVideo = _videoExtensions.contains(ext);
      final isImage =
          ext == 'png' ||
          ext == 'jpg' ||
          ext == 'jpeg' ||
          ext == 'gif' ||
          ext == 'webp';

      // Build MultipartFile depending on platform:
      // - Web: use in‑memory bytes
      // - Mobile/Desktop: use File(path)
      MultipartFile multipartFile;
      if (kIsWeb) {
        if (file.bytes == null) {
          return FileUploadResult(
            status: false,
            key: null,
            thumbnail: null,
            message: "File bytes are null in web environment.",
          );
        }
        multipartFile = MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        );
      } else {
        if (file.path == null) {
          return FileUploadResult(
            status: false,
            key: null,
            thumbnail: null,
            message: "File path is null.",
          );
        }
        multipartFile = await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        );
      }

      final formData = FormData.fromMap({
        "file": multipartFile,
        "userId": userId,
        "groupId": groupId,
        "source": "message",
        "type": isImage ? "media" : "doc",
      });

      final endpoint = isVideo
          ? "/message/fileAwsUpload"
          : "/message/fileUpload?userId=$userId&groupId=$groupId";

      final response = await api.dio.post(
        endpoint,
        data: formData,
        options: Options(contentType: "multipart/form-data"),
      );

      final data = response.data ?? {};
      final bool status = data["status"] ?? false;
      final String message = data["message"] ?? "";
      final dynamic payload = data["data"];

      return FileUploadResult(
        status: status,
        key: payload?["key"],
        thumbnail: payload?["thumbnail"],
        message: message,
      );
    } catch (e) {
      return FileUploadResult(
        status: false,
        key: null,
        thumbnail: null,
        message: e.toString(),
      );
    }
  }
}
