import 'package:chat_app/core/network/api_endpoints.dart';
import 'package:chat_app/core/network/base_response.dart';
import 'package:chat_app/core/network/dio_client.dart';

import 'package:chat_app/modules/home/models/template_model.dart';

class TemplateService {
  final DioClient api = DioClient();

  Future<BaseResponse<TemplateModel>> templates(int page) async {
    final response = await api.dio.get(
      "${ApiEndpoints.template}?page=$page&limit=10",
    );

    return BaseResponse<TemplateModel>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? TemplateModel.fromJson(response.data["data"])
          : null,
    );
  }

  Future<BaseResponse<TemplateModel>> createTemplate({
    required String name,
    required String body,
    String? url,
  }) async {
    final response = await api.dio.post(
      "${ApiEndpoints.template}",
      data: {"name": name, "body": body, "url": url},
    );

    return BaseResponse<TemplateModel>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? TemplateModel.fromJson(response.data["data"])
          : null,
    );
  }

  Future<BaseResponse<TemplateModel>> updateTemplate({
    required String id,
    required String name,
    required String body,
    String? url,
  }) async {
    final response = await api.dio.put(
      "${ApiEndpoints.template}/$id",
      data: {"name": name, "body": body, "url": url},
    );

    return BaseResponse<TemplateModel>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? TemplateModel.fromJson(response.data["data"])
          : null,
    );
  }

  Future<BaseResponse<TemplateModel>> deleteTemplate({
    required String id,
  }) async {
    final response = await api.dio.delete("${ApiEndpoints.template}/$id");

    return BaseResponse<TemplateModel>(
      status: response.data["status"] ?? false,
      message: response.data["message"] ?? "",
      data: response.data["data"] != null
          ? TemplateModel.fromJson(response.data["data"])
          : null,
    );
  }
}
