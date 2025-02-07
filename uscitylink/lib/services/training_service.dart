import 'dart:convert';

import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/question_model.dart';
import 'package:uscitylink/model/staff/assgined_driver_model.dart';
import 'package:uscitylink/model/staff/trainings_model.dart';
import 'package:uscitylink/model/training_model.dart';

class TrainingService {
  final _apiService = NetworkApiService();
  Future<ApiResponse<TrainingModel>> getTrainingVideos({
    int page = 1, // Default to page 1
    int pageSize = 15, // Default to 10 items per page
  }) async {
    try {
      dynamic response = await _apiService.getApi(
          '${Constant.url}/driver/trainings?page=$page&pageSize=$pageSize');

      if (response != null && response is Map<String, dynamic>) {
        TrainingModel dashboard = TrainingModel.fromJson(response['data']);

        return ApiResponse<TrainingModel>(
          data: dashboard,
          message: response['message'] ?? 'Get Trainings Video Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error document: $e');
    }
  }

  Future<ApiResponse<TrainingsModel>> getStaffTrainingVideos({
    int page = 1, // Default to page 1
    int pageSize = 15, // Default to 10 items per page
  }) async {
    try {
      dynamic response = await _apiService
          .getApi('${Constant.url}/trainings?page=$page&pageSize=$pageSize');

      if (response != null && response is Map<String, dynamic>) {
        TrainingsModel dashboard = TrainingsModel.fromJson(response['data']);
        return ApiResponse<TrainingsModel>(
          data: dashboard,
          message: response['message'] ?? 'Get Trainings Video Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error document: $e');
    }
  }

  Future<ApiResponse<AssginedDriverModel>> getAssginedDriver({
    String id = "",
    int page = 1, // Default to page 1
    int pageSize = 15, // Default to 10 items per page
  }) async {
    try {
      dynamic response = await _apiService.getApi(
          '${Constant.url}/trainings/assgin-drivers/$id?page=$page&pageSize=$pageSize');

      if (response != null && response is Map<String, dynamic>) {
        AssginedDriverModel dashboard =
            AssginedDriverModel.fromJson(response['data']);
        return ApiResponse<AssginedDriverModel>(
          data: dashboard,
          message: response['message'] ?? 'Get Trainings Video Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error document: $e');
    }
  }

  Future<ApiResponse<dynamic>> updateDuration(
      {String id = "",
      String view_duration = "",
      bool isCompleteWatch = false}) async {
    try {
      Map<String, dynamic> data = {
        "view_duration": view_duration,
        "isCompleteWatch": isCompleteWatch
      };
      print("hello");
      dynamic response = await _apiService.putApi(
          data, '${Constant.url}/driver/trainings/update-duration/$id');
      print(response);
      if (response != null) {
        return ApiResponse<dynamic>(
          data: {},
          message: response['message'] ?? 'Updated Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error document: $e');
    }
  }

  Future<ApiResponse<dynamic>> submitQuiz(
      {String id = "", dynamic data}) async {
    try {
      dynamic response = await _apiService.postApi(
          data, '${Constant.url}/driver/trainings/quiz-submit/$id');

      if (response != null) {
        return ApiResponse<dynamic>(
          data: response['data'],
          message: response['message'] ?? 'Submitted  Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error document: $e');
    }
  }

  Future<ApiResponse<QuestionModel>> getQuestions({
    String id = "",
  }) async {
    try {
      dynamic response = await _apiService
          .getApi('${Constant.url}/driver/trainings/training-questions/$id');

      if (response != null) {
        QuestionModel questionModel = QuestionModel.fromJson(response['data']);

        return ApiResponse<QuestionModel>(
          data: questionModel,
          message: response['message'] ?? 'Get Questions Successfully.',
          status: response['status'] ?? true,
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Error document: $e');
    }
  }
}
