import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/data/app_exceptions.dart';
import 'package:uscitylink/data/network/base_api_services.dart';
import 'package:http/http.dart' as http;
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/file_model.dart';
import 'package:uscitylink/utils/utils.dart';

class NetworkApiService extends BaseApiServices {
  UserPreferenceController userPreferenceController =
      UserPreferenceController();

  @override
  Future getApi(String url) async {
    try {
      dynamic responseJson;
      final headers = {
        'Content-Type': 'application/json',
      };

      String? token = await userPreferenceController.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(Uri.parse(url), headers: headers);
      // .timeout(const Duration(seconds: 10));

      responseJson = returnResponse(response);
      return responseJson;
    } on SocketException {
      throw InternetException();
    } on RequestTimeout {
      throw RequestTimeout();
    }
  }

  @override
  Future postApi(dynamic data, String url) async {
    try {
      Utils.showLoader();
      dynamic responseJson;
      final headers = {
        'Content-Type': 'application/json',
      };

      String? token = await userPreferenceController.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .post(Uri.parse(url), body: jsonEncode(data), headers: headers)
          .timeout(const Duration(seconds: 10));

      responseJson = returnResponse(response);
      Utils.hideLoader();
      return responseJson;
    } on SocketException {
      Utils.hideLoader();
      throw InternetException();
    } on RequestTimeout {
      Utils.hideLoader();
      throw RequestTimeout();
    }
  }

  Future putApi(dynamic data, String url) async {
    try {
      Utils.showLoader();
      dynamic responseJson;
      final headers = {
        'Content-Type': 'application/json',
      };

      String? token = await userPreferenceController.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .put(Uri.parse(url), body: jsonEncode(data), headers: headers)
          .timeout(const Duration(seconds: 10));

      responseJson = returnResponse(response);

      return responseJson;
    } on SocketException {
      Utils.hideLoader();
      throw InternetException();
    } on RequestTimeout {
      Utils.hideLoader();
      throw RequestTimeout();
    }
  }

  Future deleteApi(String url) async {
    try {
      Utils.showLoader();
      dynamic responseJson;
      final headers = {
        'Content-Type': 'application/json',
      };

      String? token = await userPreferenceController.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      responseJson = returnResponse(response);

      return responseJson;
    } on SocketException {
      Utils.hideLoader();
      throw InternetException();
    } on RequestTimeout {
      Utils.hideLoader();
      throw RequestTimeout();
    }
  }

  Future<ApiResponse<dynamic>> formData(
      String url, Map<String, dynamic> extraFields, File? file) async {
    try {
      Utils.showLoader();

      final headers = {
        'Content-Type': 'multipart/form-data',
      };

      String? token = await userPreferenceController.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers.addAll(headers);

      extraFields.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      if (file != null) {
        String fieldName = 'file'; // This is the key for the file in the form
        String filePath = file.path; // Get the path of the file

        // Add the file to the request
        var multipartFile =
            await http.MultipartFile.fromPath(fieldName, filePath);
        request.files.add(multipartFile);
      }

      final response = await request.send().timeout(const Duration(hours: 1));

      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        Map<String, dynamic> responseJson = jsonDecode(responseString);

        Utils.hideLoader();
        return ApiResponse<dynamic>(
          data: responseJson['data'] ?? {},
          message: responseJson['message'] ?? 'Uploaded successfully',
          status: responseJson['status'] ?? true,
        );
      }

      // Handle failure response
      Utils.hideLoader();
      throw Exception("SERVER ERROR: ${response.statusCode}");
    } on SocketException {
      Utils.hideLoader();
      throw InternetException(); // Handle no internet connection
    } on TimeoutException {
      Utils.hideLoader();
      throw RequestTimeout(); // Handle timeout errors
    } catch (e) {
      Utils.hideLoader();
      throw Exception(
          "An unexpected error occurred: $e"); // Handle any other exceptions
    }
  }

  Future<ApiResponse<FileModel>> fileUpload(
      File data, String url, String channelId, String type,
      [bool isLoader = true]) async {
    try {
      // Show the loader while the file is uploading
      if (isLoader) {
        Utils.showLoader();
      }

      // Prepare headers
      final headers = {
        'Content-Type':
            'multipart/form-data', // Change to 'multipart/form-data' for file upload
      };

      String? token = await userPreferenceController.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Initialize MultipartRequest
      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers.addAll(headers);
      request.fields['channelId'] = channelId;
      request.fields['type'] = type;
      // Add the file to the request
      // Add file to the request (assumes 'file' is the key for the file in your form)
      var file = await http.MultipartFile.fromPath(
        'file',
        data.path,
      );

      request.files.add(file);

      final response = await request.send().timeout(const Duration(hours: 1));

      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        Map<String, dynamic> responseJson = jsonDecode(responseString);
        FileModel fileModel = FileModel.fromJson(responseJson['data']);
        if (isLoader) {
          Utils.hideLoader();
        }

        return ApiResponse<FileModel>(
          data: fileModel,
          message: responseJson['message'] ?? 'File Uploaded successful',
          status: responseJson['status'] ?? true,
        );
      }

      if (isLoader) {
        Utils.hideLoader();
      }

      throw Exception("Unable to upload file");
    } on SocketException {
      if (isLoader) {
        Utils.hideLoader();
      }
      throw InternetException(); // Handle no internet connection
    } on TimeoutException {
      if (isLoader) {
        Utils.hideLoader();
      }
      throw RequestTimeout(); // Handle timeout errors
    } catch (e) {
      if (isLoader) {
        Utils.hideLoader();
      }
      throw Exception("An unexpected error occurred: $e");
    }
  }

  Future<ApiResponse<List<FileModel>>> multiFileUpload(
      List<File> files, String url, String channelId, String body,
      [bool isLoader = true]) async {
    try {
      // Show the loader while the files are uploading
      // if (isLoader) {
      //   Utils.showLoader();
      // }

      // Prepare headers
      final headers = {
        'Content-Type': 'multipart/form-data',
      };

      String? token = await userPreferenceController.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Initialize MultipartRequest
      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers.addAll(headers)
        ..fields['channelId'] = channelId
        ..fields['body'] = body;

      // Add each file to the request
      for (File file in files) {
        var multipartFile = await http.MultipartFile.fromPath(
          'files', // Use 'files[]' to indicate a list of files
          file.path,
        );
        request.files.add(multipartFile);
      }
      final response = await request.send().timeout(const Duration(hours: 1));
      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        Map<String, dynamic> responseJson = jsonDecode(responseString);
        List<FileModel> fileModels = (responseJson['data'] as List)
            .map((data) => FileModel.fromJson(data))
            .toList();

        return ApiResponse<List<FileModel>>(
          data: fileModels,
          message: responseJson['message'] ?? 'Files uploaded successfully',
          status: responseJson['status'] ?? true,
        );
      }

      // if (isLoader) {
      //   Utils.hideLoader();
      // }

      throw Exception("Unable to upload files");
    } on SocketException {
      if (isLoader) {
        //Utils.hideLoader();
      }
      throw InternetException(); // Handle no internet connection
    } on TimeoutException {
      if (isLoader) {
        //Utils.hideLoader();
      }
      throw RequestTimeout(); // Handle timeout errors
    } catch (e) {
      if (isLoader) {
        //Utils.hideLoader();
      }
      throw Exception("An unexpected error occurred: $e");
    }
  }

  Future<ApiResponse<VideoUpload>> videoUpload(
      File data, String url, String channelId, String type) async {
    try {
      // Prepare headers
      final headers = {
        'Content-Type': 'multipart/form-data',
      };

      String? token = await userPreferenceController.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Initialize MultipartRequest
      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers.addAll(headers);
      request.fields['channelId'] = channelId;
      request.fields['type'] = type;

      var file = await http.MultipartFile.fromPath(
        'file',
        data.path,
      );

      request.files.add(file);

      final response = await request.send().timeout(const Duration(hours: 1));

      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        Map<String, dynamic> responseJson = jsonDecode(responseString);
        VideoUpload fileModel = VideoUpload.fromJson(responseJson['data']);

        return ApiResponse<VideoUpload>(
          data: fileModel,
          message: responseJson['message'] ?? 'File Uploaded successful',
          status: responseJson['status'] ?? true,
        );
      }

      throw Exception("Unable to upload file");
    } on SocketException {
      throw InternetException();
    } on TimeoutException {
      throw RequestTimeout();
    } catch (e) {
      throw Exception("An unexpected error occurred: $e");
    }
  }
}

dynamic returnResponse(http.Response response) {
  dynamic responseJson = jsonDecode(response.body);
  switch (response.statusCode) {
    case 200:
      Utils.hideLoader();
      return responseJson;
    case 201:
      Utils.hideLoader();
      return responseJson;
    case 400:
      Utils.hideLoader();
      throw Exception(responseJson['message']);

    default:
      Utils.hideLoader();
      throw Exception(responseJson['message']);
  }
}

class VideoUpload {
  String? serverSideEncryption;
  String? location;
  String? bucket;
  String? key;
  String? eTag;
  String? thumbnail;
  VideoUpload(
      {this.serverSideEncryption,
      this.location,
      this.bucket,
      this.key,
      this.eTag,
      this.thumbnail});

  VideoUpload.fromJson(Map<String, dynamic> json) {
    serverSideEncryption = json['ServerSideEncryption'];
    location = json['Location'];
    bucket = json['Bucket'];
    key = json['Key'];
    eTag = json['ETag'];
    thumbnail = json['thumbnail'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['ServerSideEncryption'] = this.serverSideEncryption;
    data['Location'] = this.location;
    data['Bucket'] = this.bucket;
    data['Key'] = this.key;
    data['ETag'] = eTag;
    data['thumbnail'] = thumbnail;
    return data;
  }
}
