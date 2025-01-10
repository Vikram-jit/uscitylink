import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
// ignore: library_prefixes
import 'package:uscitylink/model/group_model.dart' as singleModel;
import 'package:uscitylink/model/staff/group_model.dart';
import 'package:uscitylink/model/staff/truck_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/staff_services/group_service.dart';
import 'package:uscitylink/services/group_service.dart' as groupS;
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/staff/view/group/staff_group_detail.dart';

class StaffgroupController extends GetxController {
  var innerTabIndex = 0.obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var groups = GroupModel().obs;
  var loading = false.obs;
  var truckLoader = false.obs;
  var trucks = <TruckModel>[].obs;
  var group = singleModel.GroupSingleModel().obs;
  var selectedTruck = "".obs;
  TextEditingController groupName = TextEditingController();
  var type = "truck".obs;
  void setInnerTabIndex(int index) {
    innerTabIndex.value = index;
  }

  final _groupService = GroupService();
  final __groupService = groupS.GroupService();
  @override
  void onInit() {
    super.onInit();

    getGroups(currentPage.value);
  }

  Future<void> getGroups(int page) async {
    if (loading.value) return;

    loading.value = true;

    try {
      var response = await _groupService.getGroups(
          page: page, type: type.value, pageSize: 10);

      if (response.data != null) {
        if (page > 1) {
          groups.value.data?.addAll(response.data.data ?? []);
        } else {
          groups.value = response.data;
        }

        currentPage.value = response.data.pagination!.currentPage!;
        totalPages.value = response.data.pagination!.totalPages!;
      } else {
        Utils.snackBar('No data', 'No group found.');
      }
    } catch (error) {
      Utils.snackBar('Error', error.toString());
    } finally {
      loading.value = false;
    }
  }

  Future<void> getTrucks() async {
    if (truckLoader.value) return;

    truckLoader.value = true;

    try {
      var response = await _groupService.getTruckList();

      if (response.data != null) {
        trucks.value = response.data;
      }
    } catch (error) {
      Utils.snackBar('Error', error.toString());
    } finally {
      truckLoader.value = false;
    }
  }

  Future<void> addGroup() async {
    try {
      var data = type.value == "group" ? groupName.text : selectedTruck.value;
      var response = await _groupService.addGroup(data, type.value);

      if (response.status) {
        selectedTruck.value = "";
        groupName.clear();
        groups.value.data?.insert(0, response.data);
        groups.refresh();
        Get.to(() => StaffGroupDetail(groupId: response.data.id ?? ""));
        Utils.snackBar('Success', '${response?.message}');
      } else {
        Utils.snackBar('No data', 'No group found.');
      }
    } catch (error) {
      Utils.snackBar('Error', error.toString());
    } finally {}
  }

  void getGroupById(String groupId) {
    loading.value = true;
    __groupService.getGroupById(groupId).then((response) {
      if (response.status) {
        group.value = response.data;
      }

      loading.value = false;
    }).onError((error, stackTrace) {
      loading.value = false;
      Utils.snackBar('Error', error.toString());
    });
  }

  void updateGroupCount(dynamic data) {
    if (groups.value.data?.isNotEmpty == true) {
      var groupFind = groups.value.data?.firstWhere((item) {
        return item.id == data;
      });
      if (groupFind != null) {
        groupFind.messageCount = 0;
        groups.refresh();
      }
    }
  }
}
