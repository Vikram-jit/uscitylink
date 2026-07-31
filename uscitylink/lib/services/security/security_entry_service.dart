import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/security/entry_form_data_model.dart';
import 'package:uscitylink/model/security/security_entries_page.dart';
import 'package:uscitylink/model/security/security_entry_detail.dart';
import 'package:uscitylink/model/security/trailer_status_check_result.dart';
import 'package:uscitylink/model/security/vehicle_entry_payload.dart';

class SecurityEntryService {
  final _apiService = NetworkApiService();

  Future<ApiResponse<EntryFormDataModel>> getFormData() async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/security/entries/form-data');

      if (response != null && response is Map<String, dynamic>) {
        EntryFormDataModel data = EntryFormDataModel.fromJson(response['data']);

        return ApiResponse<EntryFormDataModel>(
          data: data,
          message: response['message'] ?? 'Get Entry Form Data Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> submitEntry(
      VehicleEntryPayload payload) async {
    try {
      dynamic response = await _apiService.postApi(
          payload.toJson(), '${Constant.url}/security/entries');

      if (response != null && response is Map<String, dynamic>) {
        return ApiResponse<Map<String, dynamic>>(
          data: response['data'] ?? {},
          message: response['message'] ?? 'Vehicle entry saved successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<ApiResponse<SecurityEntriesPage>> getEntries({
    required String status,
    int page = 1,
    int pageSize = 20,
    String search = '',
  }) async {
    try {
      dynamic response = await _apiService.getApi(
          '${Constant.url}/security/entries?tab=$status&page=$page&pageSize=$pageSize&search=$search');

      if (response != null && response is Map<String, dynamic>) {
        SecurityEntriesPage data = SecurityEntriesPage.fromJson(response['data']);

        return ApiResponse<SecurityEntriesPage>(
          data: data,
          message: response['message'] ?? 'Get Entries Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<ApiResponse<SecurityEntryDetail>> getEntryDetail(int id) async {
    try {
      dynamic response =
          await _apiService.getApi('${Constant.url}/security/entries/$id');

      if (response != null && response is Map<String, dynamic>) {
        SecurityEntryDetail data = SecurityEntryDetail.fromJson(response['data']);

        return ApiResponse<SecurityEntryDetail>(
          data: data,
          message: response['message'] ?? 'Get Entry Detail Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<ApiResponse<TrailerStatusCheckResult>> checkTrailerStatus(
      int trailerId) async {
    try {
      dynamic response = await _apiService.postApi(
          {'trailerId': trailerId},
          '${Constant.url}/security/entries/check-trailer-status');

      if (response != null && response is Map<String, dynamic>) {
        TrailerStatusCheckResult data =
            TrailerStatusCheckResult.fromJson(response['data']);

        return ApiResponse<TrailerStatusCheckResult>(
          data: data,
          message: response['message'] ?? 'Checked trailer status.',
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
