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

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

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
      print(jsonEncode(data));
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

  Future<ApiResponse<FileModel>> fileUpload(
      File data, String url, String channelId, String type) async {
    try {
      // Show the loader while the file is uploading
      Utils.showLoader();

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
        Utils.hideLoader();
        return ApiResponse<FileModel>(
          data: fileModel,
          message: responseJson['message'] ?? 'File Uploaded successful',
          status: responseJson['status'] ?? true,
        );
      }

      Utils.hideLoader();

      throw Exception("Unable to upload file");
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
}

dynamic returnResponse(http.Response response) {
  dynamic responseJson = jsonDecode(response.body);
  switch (response.statusCode) {
    case 200:
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
