import 'package:get/get.dart';
import 'package:uscitylink/controller/vehicle_entry_form_controller.dart';
import 'package:uscitylink/model/security/security_entry_list_item.dart';
import 'package:uscitylink/services/security/security_entry_service.dart';

class VehicleEntryListController extends GetxController {
  final VehicleEntryStatus status;
  VehicleEntryListController(this.status);

  final _entryService = SecurityEntryService();

  var isLoading = false.obs;
  var entries = <SecurityEntryListItem>[].obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var search = ''.obs;

  bool get hasMore => currentPage.value < totalPages.value;

  @override
  void onInit() {
    super.onInit();
    fetchEntries(page: 1);
  }

  Future<void> fetchEntries({int page = 1}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      final response = await _entryService.getEntries(
        status: status.apiValue,
        page: page,
        search: search.value,
      );

      if (response.status == true) {
        if (page == 1) {
          entries.value = response.data.entries;
        } else {
          entries.addAll(response.data.entries);
        }
        currentPage.value = response.data.pagination?.currentPage ?? page;
        totalPages.value = response.data.pagination?.totalPages ?? 1;
      }
    } catch (e) {
      print('Error fetching entries: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMore() async {
    if (isLoading.value || !hasMore) return;
    await fetchEntries(page: currentPage.value + 1);
  }

  Future<void> refreshEntries() async {
    currentPage.value = 1;
    totalPages.value = 1;
    await fetchEntries(page: 1);
  }

  void applySearch(String value) {
    search.value = value;
    refreshEntries();
  }
}
