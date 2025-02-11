import 'dart:convert';

import 'package:get/get.dart';
import 'package:uscitylink/model/question_model.dart';
import 'package:uscitylink/model/staff/assgined_driver_model.dart'
    as assgined_driver;
import 'package:uscitylink/model/training_model.dart';
import 'package:uscitylink/services/training_service.dart';
import 'package:uscitylink/views/driver/views/trainings/result_view.dart';

class TrainingController extends GetxController {
  var isLoading = false.obs;
  var loadQuiz = false.obs;
  var loadDrivers = false.obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var trainings = <Training>[].obs;
  var staff_trainings = <Trainings>[].obs;
  var questions = QuestionModel().obs;
  var assgin_drivers = <assgined_driver.Drivers>[].obs;

  final _trainingService = TrainingService();

  Future<void> fetchTrainingVideos({int page = 1}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      var response = await _trainingService.getTrainingVideos(page: page);

      // Check if the response is valid
      if (response.status == true) {
        if (page > 1) {
          trainings.addAll(response.data.data ?? []);
        } else {
          trainings.value.clear();
          // Reset the message list if it's the first page
          trainings.value = response.data.data ?? [];
        }
        // Append new trucks to the list

        currentPage.value = response.data.pagination!.currentPage!;
        totalPages.value = response.data.pagination!.totalPages!;
      }
    } catch (e) {
      print("Error fetching trucks: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStaffTrainingVideos({int page = 1}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      var response = await _trainingService.getStaffTrainingVideos(page: page);

      // Check if the response is valid
      if (response.status == true) {
        if (page > 1) {
          staff_trainings.addAll(response.data.data ?? []);
        } else {
          trainings.value.clear();
          // Reset the message list if it's the first page
          staff_trainings.value = response.data.data ?? [];
        }
        // Append new trucks to the list

        currentPage.value = response.data.pagination!.currentPage!;
        totalPages.value = response.data.pagination!.totalPages!;
      }
    } catch (e) {
      print("Error fetching trucks: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAssginedDriver({String id = "", int page = 1}) async {
    if (loadDrivers.value) return;
    loadDrivers.value = true;

    try {
      var response =
          await _trainingService.getAssginedDriver(id: id, page: page);

      // Check if the response is valid
      if (response.status == true) {
        if (page > 1) {
          assgin_drivers.addAll(response.data.data?.drivers ?? []);
        } else {
          assgin_drivers.clear();
          // Reset the message list if it's the first page
          assgin_drivers.value = response.data.data?.drivers ?? [];
        }
        // Append new trucks to the list

        currentPage.value = response.data.pagination!.currentPage!;
        totalPages.value = response.data.pagination!.totalPages!;
        loadDrivers.value = false;
      }
    } catch (e) {
      print("Error fetching trucks: $e");
    } finally {
      loadDrivers.value = false;
    }
  }

  Future<void> fetchQuestion({String id = ""}) async {
    if (loadQuiz.value) return;
    loadQuiz.value = true;

    try {
      var response = await _trainingService.getQuestions(id: id);

      // Check if the response is valid
      if (response.status == true) {
        questions.value = response.data;
        loadQuiz.value = false;
      }
      loadQuiz.value = false;
    } catch (e) {
      print("Error fetching trucks: $e");
    } finally {
      loadQuiz.value = false;
    }
  }

  Future<void> updateDuration(
      String id, String view_duration, bool isCompleteWatch) async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      var response = await _trainingService.updateDuration(
          id: id,
          view_duration: view_duration,
          isCompleteWatch: isCompleteWatch);
    } catch (e) {
      print("Error fetching trucks: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitQuiz(String id, dynamic data, Training training) async {
    if (isLoading.value) return;
    isLoading.value = true;
    final convertedData = data.map((key, value) {
      return MapEntry(key, List<String>.from(value)); // Convert Set to List
    });
    try {
      var response = await _trainingService
          .submitQuiz(id: id, data: {"data": convertedData});

      if (response.status) {
        isLoading.value = false;

        Get.to(() => ResultView(
              result: response.data,
              training: training,
            ));
      }
    } catch (e) {
      print("Error fetching trucks: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
