import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/base_response.dart';
import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/modules/home/models/channel_memmber_model.dart';
import 'package:chat_app/modules/home/models/channel_model.dart';
import 'package:chat_app/modules/home/models/user_profile_model.dart';

class ChannelService {
  final DioClient api = DioClient();

  Future<BaseResponse<List<ChannelModel>>> channels() async {
    final response = await api.dio.get(ApiEndpoints.channel);

    return parseListResponse<ChannelModel>(
      response.data,
      (json) => ChannelModel.fromJson(json),
    );
  }

  Future<BaseResponse<void>> postChannel({
    required String name,
    required String description,
  }) async {
    final response = await api.dio.post(
      ApiEndpoints.channel,
      data: {"name": name, "description": description},
    );

    return BaseResponse<void>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
    );
  }

  Future<BaseResponse<void>> addMemberToChannel({
    required List<String> ids,
  }) async {
    final response = await api.dio.post(
      ApiEndpoints.addUser,
      data: {"ids": ids},
    );

    return BaseResponse<void>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
    );
  }

  Future<BaseResponse<ChannelMemmberModel>> channelMemmbers(
    int page,
    int limit,
    String? search,
    bool? paginate,
  ) async {
    final response = await api.dio.get(
      "${ApiEndpoints.channelMemmbers}?page=$page&limit=$limit&search=$search&paginate=${paginate}",
    );

    return BaseResponse<ChannelMemmberModel>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? ChannelMemmberModel.fromJson(response.data["data"])
          : null,
    );
  }

  Future<BaseResponse<List<UserProfileModel>>>
  channelMemmbersWithoutAdd() async {
    final response = await api.dio.get(ApiEndpoints.userDriver);

    final data = response.data["data"];

    return BaseResponse<List<UserProfileModel>>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: data != null
          ? (data as List).map((e) => UserProfileModel.fromJson(e)).toList()
          : [],
    );
  }
}
