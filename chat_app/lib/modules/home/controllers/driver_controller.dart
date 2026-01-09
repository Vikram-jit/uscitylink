import 'package:chat_app/modules/home/models/user_profile_model.dart';
import 'package:chat_app/modules/home/services/driver_service.dart';
import 'package:get/get.dart';

class DriverController extends GetxController {
  var isLoading = false.obs;
  var errorText = "".obs;
  RxList<UserProfileModel> users = <UserProfileModel>[].obs;

  RxInt currentPage = 1.obs;
  int itemsPerPage = 10;
  int totalItems = 0;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> getUser({int page = 1, String role = "driver"}) async {
    try {
      isLoading.value = true;
      currentPage.value = page;

      final res = await DriverService().getUsers(page, role, itemsPerPage);

      if (res.status) {
        users.assignAll(res.data?.users ?? []);
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
