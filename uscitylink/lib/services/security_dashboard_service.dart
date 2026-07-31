import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/security_dashboard_model.dart';

class SecurityDashboardService {
  final _apiService = NetworkApiService();

  Future<ApiResponse<SecurityDashboardModel>> getDashboard() async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/security/dashboard');

      if (response != null && response is Map<String, dynamic>) {
        SecurityDashboardModel dashboard =
            SecurityDashboardModel.fromJson(response['data']);

        return ApiResponse<SecurityDashboardModel>(
          data: dashboard,
          message: response['message'] ?? 'Get Security Dashboard Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }
}
