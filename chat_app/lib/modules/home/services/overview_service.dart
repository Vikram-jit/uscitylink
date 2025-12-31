import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/base_response.dart';
import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/modules/home/models/overview_model.dart';

class OverviewService {
  final DioClient api = DioClient();

  Future<BaseResponse<OverViewModel>> overview() async {
    final response = await api.dio.get(ApiEndpoints.overview);

    return BaseResponse<OverViewModel>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? OverViewModel.fromJson(response.data["data"])
          : null,
    );
  }
}
