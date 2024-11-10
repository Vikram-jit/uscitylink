import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/message_model.dart';

class MessageService {
  final _apiService = NetworkApiService();

  Future<ApiResponse<List<MessageModel>>> getChannelMessages(
      String channelId) async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/message/$channelId');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        if (data is List) {
          List<MessageModel> userChannels = data.map((channel) {
            return MessageModel.fromJson(channel);
          }).toList();

          return ApiResponse<List<MessageModel>>(
            data: userChannels,
            message: response['message'] ?? 'Get Messages Successfully.',
            status: response['status'] ?? true,
          );
        } else {
          throw Exception('Expected a list in response["data"]');
        }
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error fetching channels: $e');
    }
  }
}
