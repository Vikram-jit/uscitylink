import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/base_response.dart';
import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/models/group_response_model.dart';
import 'package:chat_app/models/truck_model.dart';
import 'package:chat_app/modules/home/models/user_reponse_model.dart';
import 'package:dio/dio.dart';

class GroupService {
  final DioClient api = DioClient();

  Future<BaseResponse<dynamic>> createGroup(Map<String, dynamic> payload) async {
    try {
      final response = await api.dio.post(ApiEndpoints.groups, data: payload);

      return BaseResponse<dynamic>(
        status: response.data["status"] ?? false,
        message: response.data["message"] ?? "",
        data: response.data["data"],
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return BaseResponse<dynamic>(
          status: data["status"] ?? false,
          message: data["message"] ?? "Request failed",
          data: data["data"],
        );
      }
      return BaseResponse<dynamic>(
        status: false,
        message: e.message ?? "Request failed",
        data: null,
      );
    }
  }

  Future<BaseResponse<GroupResponseModel>> groups(
    int page,
    int limit,
    String type,
  ) async {
    final response = await api.dio.get(
      "${ApiEndpoints.groups}?page=$page&limit=$limit&type=$type",
    );

    return BaseResponse<GroupResponseModel>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? GroupResponseModel.fromJson(response.data["data"])
          : null,
    );
  }

  Future<BaseResponse<List<TruckModel>>> truckList() async {
    final response = await api.dio.get(ApiEndpoints.truckList);

    List<TruckModel>? trucks;

    if (response.data["data"] != null) {
      trucks = (response.data["data"] as List)
          .map((e) => TruckModel.fromJson(e))
          .toList();
    }

    return BaseResponse<List<TruckModel>>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: trucks,
    );
  }

  Future<BaseResponse<UserReponseModel>> getMembers() async {
    final response = await api.dio.get(
      "${ApiEndpoints.user}?page=-1&role=driver",
    );

    return BaseResponse<UserReponseModel>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? UserReponseModel.fromJson(response.data["data"])
          : null,
    );
  }

  Future<BaseResponse<dynamic>> updateGroup({
    required String groupId,
    required String name,
    required String description,
  }) async {
    try {
      final response = await api.dio.put(
        "${ApiEndpoints.groups}/$groupId",
        data: {
          "groupId": groupId,
          "name": name,
          "description": description,
        },
      );

      return BaseResponse<dynamic>(
        status: response.data["status"] ?? false,
        message: response.data["message"] ?? "",
        data: response.data["data"],
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return BaseResponse<dynamic>(
          status: data["status"] ?? false,
          message: data["message"] ?? "Request failed",
          data: data["data"],
        );
      }
      return BaseResponse<dynamic>(
        status: false,
        message: e.message ?? "Request failed",
        data: null,
      );
    }
  }

  Future<BaseResponse<dynamic>> removeGroup(String groupId) async {
    try {
      final response =
          await api.dio.delete("${ApiEndpoints.groups}/$groupId");

      return BaseResponse<dynamic>(
        status: response.data["status"] ?? false,
        message: response.data["message"] ?? "",
        data: response.data["data"],
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return BaseResponse<dynamic>(
          status: data["status"] ?? false,
          message: data["message"] ?? "Request failed",
          data: data["data"],
        );
      }
      return BaseResponse<dynamic>(
        status: false,
        message: e.message ?? "Request failed",
        data: null,
      );
    }
  }

  Future<BaseResponse<dynamic>> addGroupMembers({
    required String groupId,
    required String membersCsv,
  }) async {
    try {
      final response = await api.dio.post(
        "${ApiEndpoints.groups}/member/$groupId",
        data: {"groupId": groupId, "members": membersCsv},
      );

      return BaseResponse<dynamic>(
        status: response.data["status"] ?? false,
        message: response.data["message"] ?? "",
        data: response.data["data"],
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return BaseResponse<dynamic>(
          status: data["status"] ?? false,
          message: data["message"] ?? "Request failed",
          data: data["data"],
        );
      }
      return BaseResponse<dynamic>(
        status: false,
        message: e.message ?? "Request failed",
        data: null,
      );
    }
  }

  Future<BaseResponse<dynamic>> removeGroupMember(String memberId) async {
    try {
      final response = await api.dio.delete(
        "${ApiEndpoints.groups}/member/$memberId",
      );

      return BaseResponse<dynamic>(
        status: response.data["status"] ?? false,
        message: response.data["message"] ?? "",
        data: response.data["data"],
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return BaseResponse<dynamic>(
          status: data["status"] ?? false,
          message: data["message"] ?? "Request failed",
          data: data["data"],
        );
      }
      return BaseResponse<dynamic>(
        status: false,
        message: e.message ?? "Request failed",
        data: null,
      );
    }
  }

  Future<BaseResponse<dynamic>> updateGroupMemberStatus({
    required String memberId,
    required String status,
  }) async {
    try {
      final response = await api.dio.put(
        "${ApiEndpoints.groups}/member/$memberId",
        data: {"groupId": memberId, "status": status},
      );

      return BaseResponse<dynamic>(
        status: response.data["status"] ?? false,
        message: response.data["message"] ?? "",
        data: response.data["data"],
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return BaseResponse<dynamic>(
          status: data["status"] ?? false,
          message: data["message"] ?? "Request failed",
          data: data["data"],
        );
      }
      return BaseResponse<dynamic>(
        status: false,
        message: e.message ?? "Request failed",
        data: null,
      );
    }
  }
}
