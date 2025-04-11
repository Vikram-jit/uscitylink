import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/group_message_model.dart';
import 'package:uscitylink/model/media_model.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/message_v2_model.dart';
import 'package:uscitylink/model/staff/truck_group_model.dart';

class MessageService {
  final _apiService = NetworkApiService();

  Future<ApiResponse<List<MessageModel>>> getChannelMessages(String channelId,
      [String? driverPin]) async {
    try {
      dynamic response = await _apiService
          .getApi('${Constant.url}/message/$channelId?driverPin=$driverPin');

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
      throw Exception('Error fetching getChannelMessages: $e');
    }
  }

  Future<ApiResponse<MessageV2Model>> getChannelMessagesV2(
      String channelId, int page,
      [String? driverPin]) async {
    try {
      dynamic response = await _apiService.getApi(
          '${Constant.url}/messageV2/$channelId?page=$page&driverPin=$driverPin');

      if (response != null) {
        var data = response['data'];

        MessageV2Model userChannels = MessageV2Model.fromJson(data);

        return ApiResponse<MessageV2Model>(
          data: userChannels,
          message: response['message'] ?? 'Get Messages Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('$e');
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
      throw Exception('Error fetching getMedia: $e');
    }
  }

  Future<ApiResponse<GroupMessageModel>> getGroupMessages(
      String channelId, String groupId, int page) async {
    try {
      dynamic response = await _apiService
          .getApi('${Constant.url}/message/$channelId/$groupId?page=$page');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        if (data != null && data is Map<String, dynamic>) {
          GroupMessageModel groupMessages = GroupMessageModel.fromJson(data);

          // Return the ApiResponse with the parsed data
          return ApiResponse<GroupMessageModel>(
            data: groupMessages,
            message: response['message'] ?? 'Get Messages Successfully.',
            status: response['status'] ?? true,
          );
        } else {
          throw Exception(
              'Expected a Map in response["data"], got: ${data.runtimeType}');
        }
      } else {
        throw Exception(
            'Unexpected response format, expected a Map<String, dynamic>');
      }
    } catch (e) {
      // Handle errors with a descriptive message
      throw Exception('Error fetching group messages: $e');
    }
  }

  Future<ApiResponse<TruckGroupModel>> getTruckGroupMessages(
      String groupId, int page) async {
    try {
      dynamic response = await _apiService
          .getApi('${Constant.url}/group/messages/$groupId?page=$page');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        if (data != null && data is Map<String, dynamic>) {
          TruckGroupModel groupMessages = TruckGroupModel.fromJson(data);

          // Return the ApiResponse with the parsed data
          return ApiResponse<TruckGroupModel>(
            data: groupMessages,
            message:
                response['message'] ?? 'Get Truck Group Messages Successfully.',
            status: response['status'] ?? true,
          );
        } else {
          throw Exception(
              'Expected a Map in response["data"], got: ${data.runtimeType}');
        }
      } else {
        throw Exception(
            'Unexpected response format, expected a Map<String, dynamic>');
      }
    } catch (e) {
      // Handle errors with a descriptive message
      throw Exception('Error fetching group messages: $e');
    }
  }
}
