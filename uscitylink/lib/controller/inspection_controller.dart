import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/inspection_model.dart';
import 'package:uscitylink/services/document_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/driver/views/driver_dashboard.dart';

class InspectionController extends GetxController {
  var isLoading = false.obs;

  var inspection = InspectionModel().obs;
  // Basic details
  var carrierName = 'US City Link Corporation'.obs;
  var inspectionDate = ''.obs;

  // Inspection items - using a map for cleaner code
  var inspectionItems = <String, bool?>{}.obs;
  var inspectionTrailerItems = <String, bool?>{}.obs;

  final selectedTrailer = ''.obs;

  void updateInspectionDate(DateTime date) {
    inspectionDate.value = '${date.month}/${date.day}/${date.year}';
  }

// Don't forget to dispose the controller

  @override
  void onInit() {
    super.onInit();
    getInspection();
    updateInspectionDate(DateTime.now());
  }

  Future<void> getInspection() async {
    // details.value = VehicleModel();
    isLoading.value = true;
    try {
      var response = await DocumentService().getInspection();

      // Check if the response is valid
      if (response.status == true) {
        inspection.value = response.data;

        if (response.status) {
          for (var item in response.data.questionsTruck!) {
            inspectionItems[item] = null;
          }
          for (var item in response.data.questionsTrailer!) {
            inspectionTrailerItems[item] = null;
          }
        }
      }
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Utils.snackBar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void updateInspectionItem(String item, bool? value) {
    inspectionItems[item] = value;
  }

  void updateInspectionTrailerItem(String item, bool? value) {
    inspectionTrailerItems[item] = value;
  }

  List<Map<String, String>> convertInspectionItems(Map<String, bool?> items) {
    return items.entries
        .where((entry) => entry.value != null) // Filter out null values
        .map((entry) {
      return {
        'question': entry.key,
        'status': entry.value! ? 'ok' : 'problem' // Convert bool to string
      };
    }).toList();
  }

  void submitInspection() async {
    var truckData = convertInspectionItems(inspectionItems);
    var trailerData = convertInspectionItems(inspectionTrailerItems);
    if (truckData.isEmpty) {
      Get.snackbar('Error', "Please complete truck inspection.");
      return;
    }

    if (selectedTrailer.value.isNotEmpty) {
      if (trailerData.isEmpty) {
        Get.snackbar('Error', "Please complete trailer inspection.");
        return;
      }
    }

    Map<String, dynamic> data = {
      "company_name": carrierName.value,
      "truck_id": inspection?.value?.getYardDriver?.id,
      "trailer_id": selectedTrailer.value.isNotEmpty
          ? inspection.value.trailers
              ?.elementAt(int.parse(selectedTrailer.value))
              .id
          : "",
      "odometer": inspection?.value?.odometerMiles,
      "inspected_at": inspectionDate.value,
      "vehicle_type": (truckData.length > 0 && trailerData.length > 0)
          ? "truckandtrailer"
          : "truck",
      "truckData": truckData,
      "trailerData": trailerData
    };

    try {
      var response = await DocumentService().updateInspection(data);

      // Check if the response is valid
      if (response.status == true) {
        Get.snackbar(
          '✅ Success',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        // Add a small delay before navigating back
        await Future.delayed(const Duration(milliseconds: 500));
        Get.to(() => const DriverDashboard());
      }
    } catch (e) {
      Utils.snackBar('Error', e.toString());
    } finally {}
  }
}
