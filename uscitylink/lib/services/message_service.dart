import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/group_message_model.dart';
import 'package:uscitylink/model/media_model.dart';
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

  Future<ApiResponse<MediaModel>> getMedia(
      String channelId, String type, String source) async {
    try {
      dynamic response = await _apiService
          .getApi('${Constant.url}/media/$channelId?type=$type&source=$source');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        if (data.containsKey('media')) {
          final mediaModel = MediaModel.fromJson(data);

          return ApiResponse<MediaModel>(
            data: mediaModel,
            message: response['message'] ?? 'Get Media Successfully.',
            status: response['status'] ?? true,
          );
        } else {
          throw Exception('Response data does not contain "media"');
        }
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error fetching channels: $e');
    }
  }

  Future<ApiResponse<GroupMessageModel>> getGroupMessages(
      String channelId, String groupId) async {
    try {
      // Make the API call
      dynamic response = await _apiService
          .getApi('${Constant.url}/message/$channelId/$groupId');

      // Check if the response is valid and has the expected structure
      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        // Check if 'data' is a valid Map
        if (data != null && data is Map<String, dynamic>) {
          // Parse the 'data' into GroupMessageModel
          GroupMessageModel groupMessages = GroupMessageModel.fromJson(data);

          // Return the ApiResponse with the parsed data
          return ApiResponse<GroupMessageModel>(
            data: groupMessages,
            message: response['message'] ?? 'Get Messages Successfully.',
            status: response['status'] ?? true,
          );
        } else {
          // If 'data' is not a Map, throw an exception
          throw Exception(
              'Expected a Map in response["data"], got: ${data.runtimeType}');
        }
      } else {
        // If the response format is incorrect or null
        throw Exception(
            'Unexpected response format, expected a Map<String, dynamic>');
      }
    } catch (e) {
      // Handle errors with a descriptive message
      throw Exception('Error fetching group messages: $e');
    }
  }
}
