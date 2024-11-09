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

class UserModel {
  String id;
  dynamic phoneNumber;
  String email;
  String status;
  DateTime createdAt;
  DateTime updatedAt;
  List<UserProfile> profiles;

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

class UserProfile {
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

  UserProfile({
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
