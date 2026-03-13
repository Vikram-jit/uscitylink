import 'package:chat_app/models/truck_model.dart';
import 'package:chat_app/modules/home/models/user_profile_model.dart';
import 'package:chat_app/modules/truck_chat/controller/group_controller.dart';
import 'package:chat_app/modules/truck_chat/services/group_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddGroupController extends GetxController {
  final name = ''.obs;
  final description = ''.obs;
  final searchQuery = ''.obs;
  final truckSearchQuery = ''.obs;

  // Text controllers for form fields
  late TextEditingController nameController;
  late TextEditingController descriptionController;

  var errorText = "".obs;

  RxList<UserProfileModel> users = <UserProfileModel>[].obs;
  RxList<TruckModel> trucks = <TruckModel>[].obs;

  RxList<UserProfileModel> selectedUsers = <UserProfileModel>[].obs;
  Rxn<TruckModel> selectedTruck = Rxn<TruckModel>();

  final isLoading = false.obs;
  final isLoadingM = false.obs;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    descriptionController = TextEditingController();
  }

  @override
  void onReady() {
    super.onReady();
    getTrucks();
    getMembers();
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    resetForm();
    super.onClose();
  }

  void resetForm() {
    name.value = '';
    description.value = '';
    nameController.clear();
    descriptionController.clear();
    selectedUsers.clear();
    selectedTruck.value = null;
    searchQuery.value = '';
    truckSearchQuery.value = '';
  }

  List<UserProfileModel> getFilteredUsers() {
    if (searchQuery.value.isEmpty) {
      return users;
    }
    return users.where((user) {
      final username = user.username?.toLowerCase() ?? '';
      final driverNumber = user.user?.driverNumber?.toLowerCase() ?? '';
      final query = searchQuery.value.toLowerCase();
      return username.contains(query) || driverNumber.contains(query);
    }).toList();
  }

  List<TruckModel> getFilteredTrucks() {
    final query = truckSearchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return trucks;
    return trucks.where((truck) {
      final number = truck.number?.toLowerCase() ?? '';
      return number.contains(query);
    }).toList();
  }

  Future<void> submit(String type) async {
    try {
      isLoading.value = true;

      final memberIds = selectedUsers
          .map((e) => e.id)
          .whereType<String>()
          .where((id) => id.trim().isNotEmpty)
          .toList();

      final groupName = type == "truck"
          ? (selectedTruck.value?.number ?? "")
          : name.value;

      if (groupName.trim().isEmpty) {
        throw Exception(
          type == "truck" ? "Please select a truck" : "Group name is required",
        );
      }

      final payload = <String, dynamic>{
        "name": groupName.trim(),
        "description": description.value.trim(),
        "type": type,
        if (memberIds.isNotEmpty) "members": memberIds.join(","),
      };

      final res = await GroupService().createGroup(payload);

      if (!res.status) {
        throw Exception(res.message.isNotEmpty ? res.message : "Create failed");
      }

      if (Get.isRegistered<GroupController>()) {
        await Get.find<GroupController>().refreshData();
      }

      Get.back();
      resetForm();
      Get.snackbar(
        "Success",
        "Add Group Successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString().replaceFirst("Exception: ", ""),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getTrucks() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      final res = await GroupService().truckList();

      if (res.status) {
        trucks.addAll(res.data ?? []);
      } else {
        errorText.value = res.message;
        print('API Error: ${res.message}');
      }
    } catch (e) {
      errorText.value = "Error: $e";
      print('Exception: $e');
    } finally {
      isLoading.value = false;
      print('Loading complete');
    }
  }

  Future<void> getMembers() async {
    if (isLoadingM.value) return;

    try {
      isLoadingM.value = true;

      final res = await GroupService().getMembers();

      if (res.status) {
        users.addAll(res.data?.users ?? []);
      } else {
        errorText.value = res.message;
        print('API Error: ${res.message}');
      }
    } catch (e) {
      errorText.value = "Error: $e";
      print('Exception: $e');
    } finally {
      isLoadingM.value = false;
      print('Loading complete');
    }
  }
}
