import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/base_response.dart';
import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/modules/auth/auth_model.dart';

class AuthService {
  final DioClient api = DioClient();

  Future<BaseResponse<AuthModel>> login(String email, String password) async {
    final response = await api.dio.post(
      ApiEndpoints.login,
      data: {"email": email, "password": password},
    );

    return BaseResponse<AuthModel>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? AuthModel.fromJson(response.data["data"]) // 👈 parse model
          : null,
    );
  }
}
