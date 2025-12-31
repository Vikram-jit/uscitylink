import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/base_response.dart';
import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/modules/home/models/channel_model.dart';

class ChannelService {
  final DioClient api = DioClient();

  Future<BaseResponse<List<ChannelModel>>> channels() async {
    final response = await api.dio.get(ApiEndpoints.channel);

    return parseListResponse<ChannelModel>(
      response.data,
      (json) => ChannelModel.fromJson(json),
    );
  }
}
