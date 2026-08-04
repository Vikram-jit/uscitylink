import 'package:get/get.dart';
import 'package:uscitylink/model/security/vehicle_inspection_history_item.dart';
import 'package:uscitylink/services/security/security_inspection_service.dart';

class VehicleInspectionHistoryController extends GetxController {
  final String tab; // 'truck' | 'trailer'
  final int vehicleId;
  VehicleInspectionHistoryController(this.tab, this.vehicleId);

  final _service = SecurityInspectionService();

  var isLoading = false.obs;
  var inspections = <VehicleInspectionHistoryItem>[].obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;

  bool get hasMore => currentPage.value < totalPages.value;

  @override
  void onInit() {
    super.onInit();
    fetchHistory(page: 1);
  }

  Future<void> fetchHistory({int page = 1}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      final response = await _service.getVehicleHistory(
        tab: tab,
        vehicleId: vehicleId,
        page: page,
      );

      if (response.status == true) {
        if (page == 1) {
          inspections.value = response.data.inspections;
        } else {
          inspections.addAll(response.data.inspections);
        }
        currentPage.value = response.data.pagination?.currentPage ?? page;
        totalPages.value = response.data.pagination?.totalPages ?? 1;
      }
    } catch (e) {
      print('Error fetching inspection history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMore() async {
    if (isLoading.value || !hasMore) return;
    await fetchHistory(page: currentPage.value + 1);
  }

  Future<void> refreshHistory() async {
    currentPage.value = 1;
    totalPages.value = 1;
    await fetchHistory(page: 1);
  }
}
