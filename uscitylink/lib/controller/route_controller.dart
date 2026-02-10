import 'package:get/get.dart';
import 'package:uscitylink/model/route_model.dart';
import 'package:uscitylink/services/document_service.dart';

class RouteController extends GetxController {
  var isLoading = false.obs;
  var routes = <RouteModel>[].obs;

  @override
  void onInit() {
    super.onInit();

    fetchRoutes();
  }

  Future<void> fetchRoutes() async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      var response = await DocumentService().getRoutes();

      // Check if the response is valid
      if (response.status == true) {
        // Append new trucks to the list
        routes.addAll(response.data);
      }
    } catch (e) {
      print("Error fetching routes: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
