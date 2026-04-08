import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/base_response.dart';
import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/models/group_message_response_model.dart';
import 'package:chat_app/models/message_response_model.dart';
import 'package:chat_app/modules/home/desktop/widgets/media_gallery.dart';
import 'package:chat_app/modules/home/models/media_model.dart';

class MessageService {
  final DioClient api = DioClient();

  Future<BaseResponse<MessageResponseModel>> getMessages(
    String userId,
    int page,
    int pageSize,
    String? pinMessage,
  ) async {
    final response = await api.dio.get(
      "${ApiEndpoints.messageByUserId}/$userId?page=$page&pageSize=$pageSize&pinMessage=$pinMessage&unreadMessage=0",
    );

    return BaseResponse<MessageResponseModel>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? MessageResponseModel.fromJson(response.data["data"])
          : null,
    );
  }

  Future<BaseResponse<MediaModelResponse>> getMediaMessages(
    String userId,
    int page,
    int pageSize,
    MediaGallerySource source,
  ) async {
    String url = ApiEndpoints.media;

    if (source.name == MediaGallerySource.group.name) {
      url =
          "$url/$userId?limit=$pageSize&page=$page&type=media&userId=$userId&source=${source.name}&private_chat_id=undefined";
    } else {
      url =
          "$url/null?limit=$pageSize&page=$page&type=media&userId=$userId&source=${source.name}&private_chat_id=undefined";
    }

    final response = await api.dio.get("$url");

    return BaseResponse<MediaModelResponse>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? MediaModelResponse.fromJson(response.data["data"])
          : null,
    );
  }

  Future<BaseResponse<GroupMessageResponseModel>> getGroupMessages(
    String groupId,
    int page,
    String? pinMessage,
  ) async {
    final response = await api.dio.get(
      "${ApiEndpoints.groupMessages}/$groupId?page=$page&pin=$pinMessage",
    );

    return BaseResponse<GroupMessageResponseModel>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? GroupMessageResponseModel.fromJson(response.data["data"])
          : null,
    );
  }
}
