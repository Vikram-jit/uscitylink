import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/base_response.dart';
import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/models/group_response_model.dart';

class GroupService {
  final DioClient api = DioClient();

  Future<BaseResponse<GroupResponseModel>> groups(
    int page,
    int limit,
    String type,
  ) async {
    final response = await api.dio.get(
      "${ApiEndpoints.groups}?page=$page&limit=$limit&type=$type",
    );

    return BaseResponse<GroupResponseModel>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? GroupResponseModel.fromJson(response.data["data"])
          : null,
    );
  }
}
