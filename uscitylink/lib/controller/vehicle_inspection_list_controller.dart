import 'package:get/get.dart';
import 'package:uscitylink/model/security/vehicle_inspection_list_item.dart';
import 'package:uscitylink/services/security/security_inspection_service.dart';

class VehicleInspectionListController extends GetxController {
  final String tab; // 'truck' | 'trailer'
  VehicleInspectionListController(this.tab);

  final _service = SecurityInspectionService();

  var isLoading = false.obs;
  var vehicles = <VehicleInspectionListItem>[].obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var filter = 'all'.obs;
  var search = ''.obs;

  bool get hasMore => currentPage.value < totalPages.value;

  @override
  void onInit() {
    super.onInit();
    fetchVehicles(page: 1);
  }

  Future<void> fetchVehicles({int page = 1}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      final response = await _service.getVehicles(
        tab: tab,
        filter: filter.value,
        page: page,
        search: search.value,
      );

      if (response.status == true) {
        if (page == 1) {
          vehicles.value = response.data.vehicles;
        } else {
          vehicles.addAll(response.data.vehicles);
        }
        currentPage.value = response.data.pagination?.currentPage ?? page;
        totalPages.value = response.data.pagination?.totalPages ?? 1;
      }
    } catch (e) {
      print('Error fetching inspection vehicles: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMore() async {
    if (isLoading.value || !hasMore) return;
    await fetchVehicles(page: currentPage.value + 1);
  }

  Future<void> refreshVehicles() async {
    currentPage.value = 1;
    totalPages.value = 1;
    await fetchVehicles(page: 1);
  }

  void applyFilter(String value) {
    filter.value = value;
    refreshVehicles();
  }

  void applySearch(String value) {
    search.value = value;
    refreshVehicles();
  }
}
