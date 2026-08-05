import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/dashboard_model.dart';
import 'package:uscitylink/model/hos_status_model.dart';
import 'package:uscitylink/model/live_location_model.dart';
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

  Future<ApiResponse<HosStatusModel>> getHosStatus() async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/user/hos-status');

      if (response != null && response is Map<String, dynamic>) {
        HosStatusModel hosStatus = HosStatusModel.fromJson(response['data']);

        return ApiResponse<HosStatusModel>(
          data: hosStatus,
          message: response['message'] ?? 'Get HOS Status Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error HOS status: $e');
    }
  }

  /// `data` may legitimately be `null` — the driver's truck has no matching
  /// Samsara live-share link — so this doesn't use `LiveLocationModel`
  /// non-nullably the way the other methods use their model types.
  Future<ApiResponse<LiveLocationModel?>> getLiveLocation() async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/user/live-location');

      if (response != null && response is Map<String, dynamic>) {
        final data = response['data'];
        final liveLocation =
            data != null ? LiveLocationModel.fromJson(data) : null;

        return ApiResponse<LiveLocationModel?>(
          data: liveLocation,
          message: response['message'] ?? 'Get Live Location Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error live location: $e');
    }
  }
}
