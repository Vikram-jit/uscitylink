import 'dart:convert';
import 'dart:io';

import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/data/app_exceptions.dart';
import 'package:uscitylink/data/network/base_api_services.dart';
import 'package:http/http.dart' as http;
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

      return responseJson;
    } on SocketException {
      Utils.hideLoader();
      throw InternetException();
    } on RequestTimeout {
      Utils.hideLoader();
      throw RequestTimeout();
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
      throw Exception("SERVER ERROR");
  }
}
