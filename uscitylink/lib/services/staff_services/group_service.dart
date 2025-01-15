import 'dart:convert';

import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/staff/group_model.dart';
import 'package:uscitylink/model/staff/truck_model.dart';
import 'package:uscitylink/model/staff/user_message_model.dart';

class GroupService {
  final _apiService = NetworkApiService();
  Future<ApiResponse<GroupModel>> getGroups(
      {int page = 1, // Default to page 1
      int pageSize = 10, // Default to 10 items per page
      String type = "group",
      String search = ""}) async {
    try {
      dynamic response = await _apiService.getApi(
          '${Constant.url}/staff/groups?page=$page&pageSize=$pageSize&type=$type&search=$search');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        if (data is Map<String, dynamic>) {
          GroupModel groups = GroupModel.fromJson(data);

          return ApiResponse<GroupModel>(
            data: groups,
            message: response['message'] ?? 'Get groups successfully.',
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

  Future<ApiResponse<Group>> addGroup(String name, String type) async {
    try {
      Map<String, dynamic> data = {
        "name": name,
        "description": "",
        "type": type,
      };
      dynamic response =
          await _apiService.postApi(data, '${Constant.url}/staff/groups');
      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];
        Group group = Group.fromJson(data);
        if (data is Map<String, dynamic>) {
          return ApiResponse<Group>(
            data: group,
            message: response['message'] ?? 'Add group successfully.',
            status: response['status'] ?? true,
          );
        } else {
          throw Exception('Expected a list in response["data"]');
        }
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception(' $e');
    }
  }

  Future<ApiResponse<List<TruckModel>>> getTruckList() async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/staff/groups/truckList');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        if (data is List) {
          List<TruckModel> trucks = data.map((channel) {
            return TruckModel.fromJson(channel);
          }).toList();

          return ApiResponse<List<TruckModel>>(
            data: trucks,
            message: response['message'] ?? 'Get trucks successfully.',
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
