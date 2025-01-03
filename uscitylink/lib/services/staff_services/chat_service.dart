import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/staff/user_message_model.dart';

class ChatService {
  final _apiService = NetworkApiService();
  Future<ApiResponse<UserMessageModel>> getMesssageByUserId(String id) async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/staff/chat/message/$id');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        if (data is Map<String, dynamic>) {
          UserMessageModel messages = UserMessageModel.fromJson(data);

          return ApiResponse<UserMessageModel>(
            data: messages,
            message: response['message'] ?? 'Get messages successfully.',
            status: response['status'] ?? true,
          );
        } else {
          throw Exception('Expected a list in response["data"]');
        }
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error fetching getMesssageByUserId: $e');
    }
  }
}
