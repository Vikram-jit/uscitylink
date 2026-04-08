// controllers/template_controller.dart

import 'package:chat_app/core/widgets/app_snackbar.dart';
import 'package:chat_app/modules/home/models/template_model.dart';
import 'package:chat_app/modules/home/services/file_upload_service.dart';
import 'package:chat_app/modules/home/services/template_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

class TemplateController extends GetxController {
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorText = ''.obs;
  final templates = <Template>[].obs;
  final currentPage = 1.obs;
  final totalItems = 0.obs;
  int itemsPerPage = 10;

  bool get hasMore => templates.length < totalItems.value;

  @override
  void onInit() {
    super.onInit();
    getTemplates(page: 1);
  }

  @override
  void onClose() {
    templates.clear();
    currentPage.value = 1;
    totalItems.value = 0;
    isLoading.value = false;
    errorText.value = '';
    super.onClose();
  }

  Future<void> getTemplates({int page = 1}) async {
    if (isLoading.value) return;
    if (page > 1 && !hasMore) return;

    isLoading.value = true;
    try {
      final res = await TemplateService().templates(page);
      if (res.status) {
        if (page == 1) {
          templates.assignAll(res.data?.data ?? []);
        } else {
          templates.addAll(res.data?.data ?? []);
        }
        totalItems.value = res.data?.pagination?.total ?? 0;
        currentPage.value = page;
      } else {
        errorText.value = res.message;
      }
    } catch (e) {
      errorText.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createTemplate({
    required String name,
    required String body,
    PlatformFile? pendingFile,
  }) async {
    isSaving.value = true;

    try {
      String? fileKey;

      // ✅ Upload only ONCE
      if (pendingFile != null) {
        final resFile = await FileUploadService().uploadForUserMessage(
          file: pendingFile,
          userId: '',
          groupId: '',
        );

        if (!resFile.status || resFile.key == null) {
          AppSnackbar.error('File upload failed, please try again.');
          return false;
        }

        fileKey = resFile.key;
      }

      // ✅ Use uploaded key
      final res = await TemplateService().createTemplate(
        name: name,
        body: body,
        url: fileKey,
      );

      if (res.status) {
        await getTemplates(page: 1);
        return true;
      }

      AppSnackbar.error(res.message);
      return false;
    } catch (e) {
      AppSnackbar.error('Something went wrong. Please try again.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateTemplate({
    required String id,
    required String name,
    required String body,
    String? url,
    PlatformFile? pendingFile,
  }) async {
    isSaving.value = true;
    try {
      if (pendingFile != null) {
        final resFile = await FileUploadService().uploadForUserMessage(
          file: pendingFile,
          userId: '',
          groupId: '',
        );
        if (!resFile.status || resFile.key == null) {
          AppSnackbar.error('File upload failed, please try again.');
          return false;
        }
        url = resFile.key;
      }

      final res = await TemplateService().updateTemplate(
        id: id,
        name: name,
        body: body,
        url: url,
      );

      if (res.status) {
        final idx = templates.indexWhere((t) => t.id.toString() == id);
        if (idx != -1) {
          templates[idx] = templates[idx].copyWith(
            name: name,
            body: body,
            url: url ?? templates[idx].url,
          );
          templates.refresh();
        }
        return true;
      }

      AppSnackbar.error(res.message);
      return false;
    } catch (e) {
      AppSnackbar.error('Something went wrong. Please try again.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteTemplate(String id) async {
    try {
      final res = await TemplateService().deleteTemplate(id: id);
      if (res.status) {
        templates.removeWhere((t) => t.id.toString() == id);
        totalItems.value = (totalItems.value - 1).clamp(0, 9999);
        return true;
      }
      AppSnackbar.error(res.message);
      return false;
    } catch (e) {
      AppSnackbar.error('Something went wrong. Please try again.');
      return false;
    }
  }
}
