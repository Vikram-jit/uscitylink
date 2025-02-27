import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/data/response/api_response.dart';
import 'package:uscitylink/model/truck_model.dart';
import 'package:uscitylink/model/vehicle_model.dart';
import 'package:uscitylink/services/document_service.dart';
import 'package:uscitylink/utils/utils.dart';

class PayController extends GetxController {
  // Rx variables to track loading state, list of trucks, and pagination
  var isLoading = false.obs;
  var pays = <Pay>[].obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var totalItems = 1.obs;
  var totalAmount = 0.0.obs;
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  void onSearchChanged(String query) {
    // If the previous timer is active, cancel it
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    // Start a new timer for debounce (500ms delay)
    _debounce = Timer(const Duration(milliseconds: 200), () {
      fetchTrucks(page: 1, search: query);
    });
  }

  Future<void> fetchTrucks(
      {int page = 1, String type = "trucks", String search = ""}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      var response =
          await DocumentService().getPays(page: page, search: search);

      // Check if the response is valid
      if (response.status == true) {
        if (page > 1) {
          pays.addAll(response.data.data ?? []);
        } else {
          // Reset the message list if it's the first page
          pays.value = response.data.data ?? [];
        }
        currentPage.value = response.data.pagination!.currentPage!;
        totalPages.value = response.data.pagination!.totalPages!;
        totalItems.value = response.data.pagination!.totalItems!;
        totalAmount.value = response.data!.totalAmount?.toDouble() ?? 0.0;
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
