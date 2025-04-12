import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/truck_model.dart';
import 'package:uscitylink/model/vehicle_model.dart';
import 'package:uscitylink/services/document_service.dart';
import 'package:uscitylink/utils/utils.dart';

class TruckController extends GetxController
    with GetSingleTickerProviderStateMixin {
  var innerTabIndex = 0.obs;
  var initialIndex = 1.obs; // Reactive variable for the initial index
  late TabController tabController;
  // Rx variables to track loading state, list of trucks, and pagination
  var isLoading = false.obs;
  var detailLoader = false.obs;
  var trucks = <Truck>[].obs; // Rx list of trucks
  var currentPage = 1.obs;
  var totalPages = 1.obs;

  var details = VehicleModel().obs;

  TextEditingController searchController = TextEditingController();
  void setInnerTabIndex(int index) {
    innerTabIndex.value = index;
  }

  void changeTab(int index) {
    initialIndex.value = index;
    tabController.animateTo(index); // Update the tab selection dynamically
    if (index == 1) {
      currentPage.value = 1;
      totalPages.value = 1;
      trucks.value = [];
      fetchTrucks(page: 1, type: "trailers");
    }

    if (index == 0) {
      currentPage.value = 1;
      totalPages.value = 1;
      trucks.value = [];
      fetchTrucks(page: 1, type: "trucks");
    }
  }

  Future<void> fetchTrucks(
      {int page = 1, String type = "trucks", String search = ""}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      var response = await DocumentService()
          .getTrucks(page: page, type: type, search: search);

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

  Future<void> fetchVehicleById({String type = "truck", String id = ""}) async {
    // details.value = VehicleModel();
    detailLoader.value = true;
    try {
      var response =
          await DocumentService().getVechicleById(id: id, type: type);

      // Check if the response is valid
      if (response.status == true) {
        details.value = response.data;
      }
      detailLoader.value = false;
    } catch (e) {
      detailLoader.value = false;
      //  Utils.snackBar('Error', e.toString());
    } finally {
      detailLoader.value = false;
    }
  }

  // Initialize the first page of data when the controller is loaded
  @override
  void onInit() {
    super.onInit();
    tabController =
        TabController(length: 2, vsync: this, initialIndex: initialIndex.value);
    fetchTrucks(page: currentPage.value);
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
