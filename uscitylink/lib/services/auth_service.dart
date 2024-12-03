import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
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

class UserModel {
  String id;
  dynamic phoneNumber;
  String email;
  String status;
  DateTime createdAt;
  DateTime updatedAt;
  List<UserProfileModel> profiles;

  UserModel({
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
