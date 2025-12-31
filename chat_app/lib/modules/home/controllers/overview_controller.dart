import 'dart:convert';

import 'package:chat_app/modules/home/models/overview_model.dart';
import 'package:chat_app/modules/home/services/overview_service.dart';
import 'package:get/get.dart';

class OverviewController extends GetxController {
  var currentTab = 0.obs; // 0 = Messages, 1 = Files, 2 = Pins
  var isLoading = false.obs;
  var errorText = "".obs;
  var overview = OverViewModel().obs;
  @override
  void onInit() {
    super.onInit();
    getOverview();
  }

  Future<void> getOverview() async {
    try {
      isLoading.value = true;

      final res = await OverviewService().overview();

      if (res.status) {
        overview.value = res.data!;
      } else {
        errorText.value = res.message;
      }
    } catch (e) {
      errorText.value = "Error: $e";
    } finally {
      isLoading.value = false;
    }
  }
}
