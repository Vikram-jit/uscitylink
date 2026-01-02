import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/base_response.dart';
import 'package:chat_app/core/network/dio_client.dart';

import 'package:chat_app/modules/home/models/user_reponse_model.dart';

class DriverService {
  final DioClient api = DioClient();

  Future<BaseResponse<UserReponseModel>> getUsers(
    int page,
    String role,
    int pageSize,
  ) async {
    final response = await api.dio.get(
      "${ApiEndpoints.user}?page=$page&limit=10&role=$role&pageSize=$pageSize",
    );

    return BaseResponse<UserReponseModel>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? UserReponseModel.fromJson(response.data["data"])
          : null,
    );
  }
}
