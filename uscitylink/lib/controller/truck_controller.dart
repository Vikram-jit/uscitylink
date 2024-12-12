import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/truck_model.dart';
import 'package:uscitylink/services/document_service.dart';

class TruckController extends GetxController {
  // Rx variables to track loading state, list of trucks, and pagination
  var isLoading = false.obs;
  var trucks = <Truck>[].obs; // Rx list of trucks
  var currentPage = 1.obs;
  var totalPages = 1.obs;

  // Method to fetch trucks with pagination
  Future<void> fetchTrucks({int page = 1}) async {
    if (isLoading.value) return; // Prevent multiple fetches at the same time
    isLoading.value = true;

    try {
      // Call the API service to fetch trucks data for the given page
      var response = await DocumentService().getTrucks(page: page);

      // Check if the response is valid
      if (response.status == true) {
        // Append new trucks to the list
        trucks.addAll(response.data.data ?? []);
        currentPage.value = response.data.pagination!.currentPage!;
        totalPages.value = response.data.pagination!.totalPages!;
      }
    } catch (e) {
      print("Error fetching trucks: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Initialize the first page of data when the controller is loaded
  @override
  void onInit() {
    super.onInit();
    fetchTrucks(page: currentPage.value);
  }
}
