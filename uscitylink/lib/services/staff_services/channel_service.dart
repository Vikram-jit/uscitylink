import 'dart:convert';

import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/group_members_model.dart';
import 'package:uscitylink/model/staff/channel_chat_user_model.dart';
import 'package:uscitylink/model/staff/channel_member_model.dart';
import 'package:uscitylink/model/staff/channel_model.dart';
import 'package:uscitylink/model/staff/driver_model.dart';
import 'package:uscitylink/model/staff/driver_pagination_model.dart';
import 'package:uscitylink/model/template_model.dart';
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
      throw Exception('Error fetching getChannelList: $e');
    }
  }

  Future<ApiResponse<ChannelChatUserModel>> getChatUserChannel(
      int page, String search, String type) async {
    try {
      dynamic response = await _apiService.getApi(
          '${Constant.url}/staff/channel/chatUsers?page=$page&search=$search&type=$type');

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
      throw Exception('Error fetching getChatUserChannel: $e');
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
      throw Exception('Error fetching getStaffChannelMember: $e');
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
      throw Exception('Error fetching getStaffDrivers: $e');
    }
  }

  Future<ApiResponse<List<DriverModel>>> getStaffGroupDrivers(
      String groupId) async {
    try {
      dynamic response = await _apiService
          .getApi('${Constant.url}/staff/groups/$groupId/drivers');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        if (data is List) {
          List<DriverModel> channels = data.map((channel) {
            return DriverModel.fromJson(channel);
          }).toList();

          return ApiResponse<List<DriverModel>>(
            data: channels,
            message:
                response['message'] ?? 'Get Group Driver List Successfully.',
            status: response['status'] ?? true,
          );
        } else {
          throw Exception('Expected a list in response["data"]');
        }
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error fetching getStaffDrivers: $e');
    }
  }

  Future<ApiResponse<DriverPaginationModel>> getDrivers(int page) async {
    try {
      dynamic response = await _apiService
          .getApi('${Constant.url}/staff/channel/driver-list?page=$page');

      if (response != null) {
        var data = response['data'];

        if (data is Map<String, dynamic>) {
          DriverPaginationModel drivers = DriverPaginationModel.fromJson(data);

          return ApiResponse<DriverPaginationModel>(
            data: drivers,
            message:
                response['message'] ?? 'Get Group Driver List Successfully.',
            status: response['status'] ?? true,
          );
        } else {
          throw Exception('Expected a list in response["data"]');
        }
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      print(e);
      throw Exception('Error fetching getStaffDrivers: $e');
    }
  }

  Future<ApiResponse<TemplateModel>> getTemplates(
      int page, String search) async {
    try {
      dynamic response = await _apiService.getApi(
          '${Constant.url}/template?page=$page&source=paginationWithSearch&search=$search');

      if (response != null) {
        var data = response['data'];

        if (data is Map<String, dynamic>) {
          TemplateModel templates = TemplateModel.fromJson(data);

          return ApiResponse<TemplateModel>(
            data: templates,
            message: response['message'] ?? 'Get Template List Successfully.',
            status: response['status'] ?? true,
          );
        } else {
          throw Exception('Expected a list in response["data"]');
        }
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      print(e);
      throw Exception('Error fetching template: $e');
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
      throw Exception('Error fetching updateChannelMembers: $e');
    }
  }

  Future<ApiResponse<EventGroupMemberModel>> updateGroupMembers(
      String id, String groupId) async {
    try {
      Map<String, dynamic> data = {'id': id, 'groupId': groupId};
      dynamic response = await _apiService.putApi(
          data, '${Constant.url}/staff/groups/addMember');

      if (response != null) {
        var data = response['status'];

        if (data is bool) {
          EventGroupMemberModel eventGroupMemberModel =
              EventGroupMemberModel.fromJson(response['data']);
          Utils.toastMessage(
              response['message'] ?? 'Updated group members successfully.');
          return ApiResponse<EventGroupMemberModel>(
            data: eventGroupMemberModel,
            message:
                response['message'] ?? 'Updated group members successfully.',
            status: response['status'] ?? true,
          );
        } else {
          throw Exception('Expected a list in response["data"]');
        }
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      if (e.toString().contains('This group currently has 2 members')) {
        // Specific handling for the case where the group has 2 members
        throw Exception(
            'Cannot add a new member. This group currently has 2 members. Please disable or delete an existing member.');
      } else {
        // General exception handling
        throw Exception('Error fetching updateGroupMembers: $e');
      }
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
      throw Exception('Error fetching updateActiveChannel: $e');
    }
  }
}
