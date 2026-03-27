import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/base_response.dart';
import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/modules/broadcast_messages/broadcast_model.dart';

class BroadcastService {
  final DioClient api = DioClient();

  Future<BaseResponse<BroadcastResponse>> getBroadcastMessages(
    int page,
    int pageSize,
  ) async {
    final response = await api.dio.get(
      "${ApiEndpoints.messageBroadcast}?page=$page&pageSize=$pageSize&pinMessage=0&unreadMessage=0",
    );

    return BaseResponse<BroadcastResponse>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? BroadcastResponse.fromJson(response.data["data"])
          : null,
    );
  }
}
