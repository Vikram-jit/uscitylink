import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/dashboard_model.dart';
import 'package:uscitylink/model/staff/staff_dashboard_model.dart';

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
      throw Exception('$e');
    }
  }

  Future<ApiResponse<StaffDashboardModel>> getDashboardStaff() async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/user/dashboard-web');

      if (response != null && response is Map<String, dynamic>) {
        var data = response['data'];

        StaffDashboardModel dashboard =
            StaffDashboardModel.fromJson(response['data']);

        return ApiResponse<StaffDashboardModel>(
          data: dashboard,
          message: response['message'] ?? 'Get Dashboard Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error dashboard: $e');
    }
  }
}
