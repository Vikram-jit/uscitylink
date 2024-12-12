import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/dashboard_model.dart';

class DashboardService {
  final _apiService = NetworkApiService();
  Future<ApiResponse<DashboardModel>> getDashboard() async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/user/dashboard');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        DashboardModel dashboard = DashboardModel.fromJson(response['data']);

        return ApiResponse<DashboardModel>(
          data: dashboard,
          message: response['message'] ?? 'Get Dashboard Successfully.',
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
