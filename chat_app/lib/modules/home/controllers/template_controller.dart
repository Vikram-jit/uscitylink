import 'package:chat_app/modules/home/models/channel_memmber_model.dart';
import 'package:chat_app/modules/home/models/channel_model.dart';
import 'package:chat_app/modules/home/models/overview_model.dart';
import 'package:chat_app/modules/home/models/template_model.dart';
import 'package:chat_app/modules/home/services/channel_service.dart';
import 'package:chat_app/modules/home/services/template_service.dart';
import 'package:get/get.dart';

class TemplateController extends GetxController {
  var isLoading = false.obs;
  var errorText = "".obs;
  RxList<Template> templates = <Template>[].obs;

  RxInt currentPage = 1.obs;
  int itemsPerPage = 10;
  int totalItems = 0;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> getTemplates({int page = 1}) async {
    try {
      isLoading.value = true;
      currentPage.value = page;

      final res = await TemplateService().templates(page);

      if (res.status) {
        templates.assignAll(res.data?.data ?? []);
        totalItems = res.data?.pagination?.total ?? 0;
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
