import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/group_model.dart';
import 'package:uscitylink/model/user_channel_model.dart';

class GroupService {
  final _apiService = NetworkApiService();
  Future<ApiResponse<List<GroupModel>>> getUserGroups() async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/user/groups');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        if (data is List) {
          List<GroupModel> userGroups = data.map((channel) {
            return GroupModel.fromJson(channel);
          }).toList();

          return ApiResponse<List<GroupModel>>(
            data: userGroups,
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
      throw Exception('$e');
    }
  }

  Future<ApiResponse<GroupSingleModel>> getGroupById(String groupId) async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/group/$groupId');

      if (response != null && response['data'] != null) {
        var data = response['data'];

        GroupSingleModel group = GroupSingleModel.fromJson(data);
        return ApiResponse<GroupSingleModel>(
          data: group,
          message: response['message'] ?? 'Get Users List Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error fetching groupbyid: $e');
    }
  }

  Future<ApiResponse<Null>> deletedById(String id) async {
    try {
      dynamic response =
          await _apiService.deleteApi('${Constant.url}/group/$id');

      if (response != null) {
        /// var data = response['data'];

        return ApiResponse<Null>(
          data: null,
          message: response['message'] ?? 'Deleted Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error Deleted : $e');
    }
  }

  Future<ApiResponse<Null>> deleteGroupMemberById(String id) async {
    try {
      dynamic response =
          await _apiService.deleteApi('${Constant.url}/group/member/$id');

      if (response != null) {
        /// var data = response['data'];

        return ApiResponse<Null>(
          data: null,
          message: response['message'] ?? 'Deleted Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error Deleted : $e');
    }
  }

  Future<ApiResponse<Null>> updateStatusGroupMemberById(
      String status, String id) async {
    try {
      Map<String, String> obj = {"status": status};
      dynamic response =
          await _apiService.putApi(obj, '${Constant.url}/group/member/$id');

      if (response != null) {
        /// var data = response['data'];

        return ApiResponse<Null>(
          data: null,
          message: response['message'] ?? 'Deleted Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error Deleted : $e');
    }
  }
}
