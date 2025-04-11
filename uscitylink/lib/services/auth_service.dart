import 'dart:convert';

import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/driver_model.dart';
import 'package:uscitylink/model/login_model.dart';

class AuthService {
  final _apiService = NetworkApiService();

  Future<ApiResponse<LoginModel>> login(var data) async {
    dynamic response =
        await _apiService.postApi(data, '${Constant.url}/auth/login');

    if (response != null) {
      LoginModel loginModel = LoginModel.fromJson(response['data']);

      return ApiResponse<LoginModel>(
        data: loginModel,
        message: response['message'] ?? 'Login successful',
        status: response['status'] ?? true,
      );
    } else {
      throw Exception('Failed to log in');
    }
  }

  Future<ApiResponse<dynamic>> getOtp(var data) async {
    dynamic response =
        await _apiService.postApi(data, '${Constant.url}/auth/sendOtp');

    if (response != null) {
      return ApiResponse<dynamic>(
        data: {},
        message: response['message'] ?? 'Send otp successful',
        status: response['status'] ?? true,
      );
    } else {
      throw Exception('Failed to log in');
    }
  }

  Future<ApiResponse<dynamic>> logout() async {
    dynamic response =
        await _apiService.postApi({}, '${Constant.url}/auth/logout');

    if (response != null) {
      return ApiResponse<dynamic>(
        data: {},
        message: response['message'] ?? 'Logout successful',
        status: response['status'] ?? true,
      );
    } else {
      throw Exception('Failed to log in');
    }
  }

  Future<ApiResponse<dynamic>> resendOtp(var data) async {
    dynamic response =
        await _apiService.postApi(data, '${Constant.url}/auth/re-sendOtp');

    if (response != null) {
      return ApiResponse<dynamic>(
        data: {},
        message: response['message'] ?? 'Send otp successful',
        status: response['status'] ?? true,
      );
    } else {
      throw Exception('Failed to log in');
    }
  }

  Future<ApiResponse<LoginWithPasswordModel>> loginWithPassword(
      LoginWithPassword data) async {
    Map<String, dynamic> requestData = data.toJson();

    dynamic response = await _apiService.postApi(
        requestData, '${Constant.url}/auth/loginWithPassword');

    if (response != null && response['data'] != null) {
      LoginWithPasswordModel loginModel =
          LoginWithPasswordModel.fromJson(response['data']);

      return ApiResponse<LoginWithPasswordModel>(
        data: loginModel,
        message: response['message'] ?? 'Login successful',
        status: response['status'] ?? true,
      );
    } else {
      throw Exception('Failed to log in: No valid data received.');
    }
  }

  Future<ApiResponse<LoginWithPasswordModel>> verifyOtp(
      LoginWithOTP data) async {
    Map<String, dynamic> requestData = data.toJson();

    dynamic response = await _apiService.postApi(
        requestData, '${Constant.url}/auth/validateOtp');

    if (response != null && response['data'] != null) {
      LoginWithPasswordModel loginModel =
          LoginWithPasswordModel.fromJson(response['data']);

      return ApiResponse<LoginWithPasswordModel>(
        data: loginModel,
        message: response['message'] ?? 'Login successful',
        status: response['status'] ?? true,
      );
    } else {
      throw Exception('Failed to log in: No valid data received.');
    }
  }

  Future<ApiResponse<Profiles>> getProfile() async {
    dynamic response = await _apiService.getApi('${Constant.url}/user/profile');

    if (response != null && response['data'] != null) {
      Profiles userProfile = Profiles.fromJson(response['data']);

      return ApiResponse<Profiles>(
        data: userProfile,
        message: response['message'] ?? 'User Profile successful',
        status: response['status'] ?? true,
      );
    } else {
      throw Exception('Failed to log in: No valid data received.');
    }
  }

  Future<ApiResponse<DriverModel>> getDriverProfile() async {
    dynamic response =
        await _apiService.getApi('${Constant.url}/user/driver-profile');

    if (response != null && response['data'] != null) {
      DriverModel userProfile = DriverModel.fromJson(response['data']);

      return ApiResponse<DriverModel>(
        data: userProfile,
        message: response['message'] ?? 'Driver Profile successful',
        status: response['status'] ?? true,
      );
    } else {
      throw Exception('Failed to fetch driver profile.');
    }
  }

  Future<ApiResponse<dynamic>> updateDeviceToken(DeviceTokenUpdate data) async {
    dynamic response = await _apiService.putApi(
        data.toJson(), '${Constant.url}/user/updateDeviceToken');

    if (response != null && response['status']) {
      return ApiResponse<dynamic>(
        data: {},
        message: response['message'] ?? 'Device Token Updated successful',
        status: response['status'] ?? true,
      );
    } else {
      throw Exception('Failed to log in: No valid data received.');
    }
  }

  Future<ApiResponse<String>> updateAppVersion(AppUpdateInfo data) async {
    dynamic response = await _apiService.putApi(
        data.toJson(), '${Constant.url}/auth/updateAppVersion');

    if (response != null && response['status']) {
      return ApiResponse<String>(
        data: response['data'],
        message: response['message'] ?? 'Device Info Updated successful',
        status: response['status'] ?? true,
      );
    } else {
      throw Exception('Failed to log in: No valid data received.');
    }
  }

  Future<ApiResponse<dynamic>> changePassword(var data) async {
    dynamic response =
        await _apiService.postApi(data, '${Constant.url}/user/change-password');

    if (response != null) {
      return ApiResponse<dynamic>(
        data: {},
        message: response['message'] ?? 'Change password successful',
        status: response['status'] ?? true,
      );
    } else {
      throw Exception('Failed to change password');
    }
  }
}

class LoginWithPassword {
  final String email;
  final String password;
  final String role;

  LoginWithPassword(
      {required this.email, required this.password, required this.role});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'role': role,
    };
  }
}

class LoginWithOTP {
  final String email;
  final String otp;

  LoginWithOTP({required this.email, required this.otp});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
    };
  }
}

class DeviceTokenUpdate {
  final String token;
  final String platform;

  DeviceTokenUpdate({
    required this.token,
    required this.platform,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_token': token,
      'platform': platform,
    };
  }
}

class AppUpdateInfo {
  final String buildNumber;
  final String version;
  final String platform;

  AppUpdateInfo(
      {required this.buildNumber,
      required this.version,
      required this.platform});

  Map<String, dynamic> toJson() {
    return {
      'buildNumber': buildNumber,
      'version': version,
      'platform': platform
    };
  }
}

class UserModelAuth {
  String id;
  dynamic phoneNumber;
  String email;
  String status;
  DateTime createdAt;
  DateTime updatedAt;
  List<UserProfileModel> profiles;

  UserModelAuth({
    required this.id,
    required this.phoneNumber,
    required this.email,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.profiles,
  });
}

class UserProfileModel {
  String id;
  String userId;
  String username;
  dynamic profilePic;
  String status;
  int roleId;
  dynamic lastMessageId;
  bool isOnline;
  dynamic deviceId;
  dynamic deviceToken;
  dynamic platform;
  DateTime lastLogin;
  DateTime createdAt;
  DateTime updatedAt;
  Role role;

  UserProfileModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.profilePic,
    required this.status,
    required this.roleId,
    required this.lastMessageId,
    required this.isOnline,
    required this.deviceId,
    required this.deviceToken,
    required this.platform,
    required this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    required this.role,
  });
}

class Role {
  int id;
  String name;
  DateTime createdAt;
  DateTime updatedAt;

  Role({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });
}
