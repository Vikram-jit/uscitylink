import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/base_response.dart';
import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/models/message_response_model.dart';

class MessageService {
  final DioClient api = DioClient();

  Future<BaseResponse<MessageResponseModel>> getMessages(
    String userId,
    int page,
    int pageSize,
  ) async {
    final response = await api.dio.get(
      "${ApiEndpoints.messageByUserId}/$userId?page=$page&pageSize=$pageSize&pinMessage=0&unreadMessage=0",
    );

    return BaseResponse<MessageResponseModel>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? MessageResponseModel.fromJson(response.data["data"])
          : null,
    );
  }
}
