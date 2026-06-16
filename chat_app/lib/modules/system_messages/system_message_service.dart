import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/base_response.dart';
import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/modules/system_messages/system_message_model.dart';

class SystemMessageService {
  final DioClient api = DioClient();

  Future<BaseResponse<SystemMessageResponse>> getSystemMessages(
    int page,
    int pageSize, {
    String search = '',
    String completedBy = '',
    String startDate = '',
    String endDate = '',
  }) async {
    final response = await api.dio.get(
      '${ApiEndpoints.systemMessages}?page=$page&pageSize=$pageSize'
      '&search=$search&completedBy=$completedBy'
      '&startDate=$startDate&endDate=$endDate',
    );

    return BaseResponse<SystemMessageResponse>(
      status: response.data['status'] ?? false,
      message: response.data['message'] ?? '',
      data: response.data['data'] != null
          ? SystemMessageResponse.fromJson(response.data['data'])
          : null,
    );
  }

  Future<BaseResponse<SystemMessageResponse>> getSystemUnreadMessages() async {
    final response = await api.dio.get(ApiEndpoints.systemMessagesUnread);

    return BaseResponse<SystemMessageResponse>(
      status: response.data['status'] ?? false,
      message: response.data['message'] ?? '',
      data: response.data['data'] != null
          ? SystemMessageResponse.fromJson(response.data['data'])
          : null,
    );
  }

  Future<bool> markComplete(String id) async {
    final response = await api.dio.put(
      '${ApiEndpoints.systemMessages}/$id/complete',
    );
    return response.data['status'] == true;
  }

  Future<bool> markAllRead() async {
    final response = await api.dio.put(
      ApiEndpoints.systemMessagesMarkAllRead,
    );
    return response.data['status'] == true;
  }

  Future<BaseResponse<StaffUserResponse>> getStaffUsers() async {
    final response = await api.dio.get(
      '${ApiEndpoints.user}?role=staff&page=-1&search=',
    );

    return BaseResponse<StaffUserResponse>(
      status: response.data['status'] ?? false,
      message: response.data['message'] ?? '',
      data: response.data['data'] != null
          ? StaffUserResponse.fromJson(response.data['data'])
          : null,
    );
  }
}
