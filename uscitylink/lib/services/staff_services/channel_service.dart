import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/staff/channel_chat_user_model.dart';
import 'package:uscitylink/model/staff/channel_member_model.dart';
import 'package:uscitylink/model/staff/channel_model.dart';
import 'package:uscitylink/model/staff/driver_model.dart';
import 'package:uscitylink/model/user_channel_model.dart';
import 'package:uscitylink/utils/utils.dart';

class ChannelService {
  final _apiService = NetworkApiService();
  Future<ApiResponse<List<ChannelModel>>> getChannelList() async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/staff/channel/channels');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        if (data is List) {
          List<ChannelModel> channels = data.map((channel) {
            return ChannelModel.fromJson(channel);
          }).toList();

          return ApiResponse<List<ChannelModel>>(
            data: channels,
            message: response['message'] ?? 'Get Channel List Successfully.',
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

  Future<ApiResponse<ChannelChatUserModel>> getChatUserChannel() async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/staff/channel/chatUsers');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        if (data is Map<String, dynamic>) {
          ChannelChatUserModel channels = ChannelChatUserModel.fromJson(data);

          return ApiResponse<ChannelChatUserModel>(
            data: channels,
            message: response['message'] ?? 'Get Channel List Successfully.',
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

  Future<ApiResponse<List<ChannelMemberModel>>> getStaffChannelMember() async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/staff/channel/members');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        if (data is List) {
          List<ChannelMemberModel> channels = data.map((channel) {
            return ChannelMemberModel.fromJson(channel);
          }).toList();

          return ApiResponse<List<ChannelMemberModel>>(
            data: channels,
            message:
                response['message'] ?? 'Get Channel Members List Successfully.',
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

  Future<ApiResponse<List<DriverModel>>> getStaffDrivers() async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/staff/channel/drivers');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        if (data is List) {
          List<DriverModel> channels = data.map((channel) {
            return DriverModel.fromJson(channel);
          }).toList();

          return ApiResponse<List<DriverModel>>(
            data: channels,
            message: response['message'] ?? 'Get Driver List Successfully.',
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

  Future<ApiResponse<dynamic>> updateChannelMembers(String id) async {
    try {
      Map<String, dynamic> data = {'id': id};
      dynamic response = await _apiService.putApi(
          data, '${Constant.url}/staff/channel/addOrRemoveDriverFromChannel');

      if (response != null) {
        var data = response['status'];

        if (data is bool) {
          Utils.toastMessage(
              response['message'] ?? 'Updated channel members successfully.');
          return ApiResponse<dynamic>(
            data: {},
            message:
                response['message'] ?? 'Updated channel members successfully.',
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

  Future<ApiResponse<dynamic>> updateActiveChannel(String id) async {
    try {
      Map<String, dynamic> data = {'id': id};
      dynamic response = await _apiService.putApi(
          data, '${Constant.url}/staff/channel/updateStaffActiceChannel');

      if (response != null) {
        var data = response['status'];

        if (data is bool) {
          Utils.toastMessage(
              response['message'] ?? 'Swtich channel successfully.');
          return ApiResponse<dynamic>(
            data: {},
            message:
                response['message'] ?? 'Updated channel members successfully.',
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
