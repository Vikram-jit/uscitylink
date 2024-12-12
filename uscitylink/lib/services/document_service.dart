import 'dart:convert';

import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/truck_model.dart';

class DocumentService {
  final _apiService = NetworkApiService();
  Future<ApiResponse<TruckModel>> getTrucks({
    int page = 1, // Default to page 1
    int pageSize = 15, // Default to 10 items per page
  }) async {
    try {
      dynamic response = await _apiService
          .getApi('${Constant.url}/yard/trucks?page=$page&pageSize=$pageSize');

      if (response != null && response is Map<String, dynamic>) {
        TruckModel dashboard = TruckModel.fromJson(response['data']);

        return ApiResponse<TruckModel>(
          data: dashboard,
          message: response['message'] ?? 'Get Truck Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error fetching channels: $e');
    }
  }
}