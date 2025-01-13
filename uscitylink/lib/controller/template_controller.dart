import 'package:get/get.dart';
import 'package:uscitylink/model/staff/driver_pagination_model.dart';
import 'package:uscitylink/model/template_model.dart';
import 'package:uscitylink/services/staff_services/channel_service.dart';
import 'package:uscitylink/utils/utils.dart';

class TemplateController extends GetxController {
  var templates = <Template>[].obs;

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
}
