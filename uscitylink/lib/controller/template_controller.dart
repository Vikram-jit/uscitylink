import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/model/staff/driver_pagination_model.dart';
import 'package:uscitylink/model/template_model.dart';
import 'package:uscitylink/services/staff_services/channel_service.dart';
import 'package:uscitylink/utils/utils.dart';

class TemplateController extends GetxController {
  var templates = <Template>[].obs;
  final _apiService = NetworkApiService();

  final __channelService = ChannelService();
  var loading = false.obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;

  void getTemplates(int page) {
    loading.value = true;
    __channelService.getTemplates(page).then((response) {
      templates.addAll(response.data.data ?? []);
      currentPage.value = response.data.pagination!.currentPage!;
      totalPages.value = response.data.pagination!.totalPages!;
      loading.value = false;
    }).onError((error, stackTrace) {
      loading.value = false;
      Utils.snackBar('Error', error.toString());
    });
  }

  void templateAction(Map<String, dynamic> data, File? file) async {
    try {
      var response = await _apiService.formData(
          '${Constant.url}/template/createOrUpdate', data, file);
      if (response.status) {
        Template template = Template.fromJson(response.data);

        if (data["action"] == "add") {
          templates.insert(0, template);
        } else if (data["action"] == "delete") {
          templates.removeWhere((item) => item.id == template.id);
          Get.back();
        } else {
          var index = templates.indexWhere((item) => item.id == template.id);
          templates.removeWhere((item) => item.id == template.id);
          templates.insert(index, template);
        }
        templates.refresh();
        update();
        Utils.toastMessage(response.message);
        Get.back();
      }
    } catch (e) {
      Utils.snackBar('Error', e.toString());
      print(e);
    }
  }
}
