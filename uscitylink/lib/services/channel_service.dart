import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/user_channel_model.dart';

class ChannelService {
  final _apiService = NetworkApiService();
  Future<ApiResponse<List<UserChannelModel>>> getUserChannels() async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/user/channels');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        if (data is List) {
          List<UserChannelModel> userChannels = data.map((channel) {
            return UserChannelModel.fromJson(channel);
          }).toList();

          return ApiResponse<List<UserChannelModel>>(
            data: userChannels,
            message: response['message'] ?? 'Get Users List Successfully.',
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
