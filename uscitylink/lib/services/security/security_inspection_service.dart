import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/security/inspection_detail.dart';
import 'package:uscitylink/model/security/inspection_odometer_result.dart';
import 'package:uscitylink/model/security/inspection_questions_response.dart';
import 'package:uscitylink/model/security/vehicle_inspection_history_item.dart';
import 'package:uscitylink/model/security/vehicle_inspection_list_item.dart';

class SecurityInspectionService {
  final _apiService = NetworkApiService();

  Future<ApiResponse<InspectionQuestionsResponse>> getQuestions() async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/security/inspections/questions');

      if (response != null && response is Map<String, dynamic>) {
        return ApiResponse<InspectionQuestionsResponse>(
          data: InspectionQuestionsResponse.fromJson(response['data']),
          message: response['message'] ?? 'Get Inspection Questions Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<ApiResponse<InspectionOdometerResult>> getOdometer(int truckId) async {
    try {
      dynamic response = await _apiService
          .getApi('${Constant.url}/security/inspections/odometer/$truckId');

      if (response != null && response is Map<String, dynamic>) {
        return ApiResponse<InspectionOdometerResult>(
          data: InspectionOdometerResult.fromJson(response['data']),
          message: response['message'] ?? 'Get Odometer Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<ApiResponse<VehicleInspectionListPage>> getVehicles({
    required String tab,
    String filter = 'all',
    int page = 1,
    int pageSize = 20,
    String search = '',
  }) async {
    try {
      dynamic response = await _apiService.getApi(
          '${Constant.url}/security/inspections?tab=$tab&filter=$filter&page=$page&pageSize=$pageSize&search=$search');

      if (response != null && response is Map<String, dynamic>) {
        return ApiResponse<VehicleInspectionListPage>(
          data: VehicleInspectionListPage.fromJson(response['data']),
          message: response['message'] ?? 'Get Inspection Vehicles Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<ApiResponse<VehicleInspectionHistoryPage>> getVehicleHistory({
    required String tab,
    required int vehicleId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      dynamic response = await _apiService.getApi(
          '${Constant.url}/security/inspections/vehicle/$tab/$vehicleId?page=$page&pageSize=$pageSize');

      if (response != null && response is Map<String, dynamic>) {
        return ApiResponse<VehicleInspectionHistoryPage>(
          data: VehicleInspectionHistoryPage.fromJson(response['data']),
          message: response['message'] ?? 'Get Vehicle Inspection History Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<ApiResponse<InspectionDetail>> getInspectionDetail(int id) async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/security/inspections/$id');

      if (response != null && response is Map<String, dynamic>) {
        return ApiResponse<InspectionDetail>(
          data: InspectionDetail.fromJson(response['data']),
          message: response['message'] ?? 'Get Inspection Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createInspection(
      Map<String, dynamic> payload) async {
    try {
      // showLoader: false — the form already shows its own inline submit
      // spinner; skipping the global blocking dialog here avoids a race
      // where a fast request resolves before GetX finishes registering the
      // dialog as open, leaving it stuck and swallowing this screen's own
      // post-submit navigation.
      dynamic response = await _apiService.postApi(
          payload, '${Constant.url}/security/inspections',
          showLoader: false);

      if (response != null && response is Map<String, dynamic>) {
        return ApiResponse<Map<String, dynamic>>(
          data: response['data'] ?? {},
          message: response['message'] ?? 'Inspection submitted successfully.',
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
