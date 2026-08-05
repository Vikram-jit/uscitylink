import 'package:get/get.dart';
import 'package:uscitylink/model/live_location_model.dart';
import 'package:uscitylink/services/dashboard_service.dart';

/// The driver's truck's live-share location link from Samsara, if one
/// exists. Deliberately three-state (`hasFetched` false / `liveLocation`
/// null / `liveLocation` set) rather than defaulting to an empty model, so
/// the dashboard card can tell "still loading" apart from "genuinely no
/// live share available for this truck."
class LiveLocationController extends GetxController {
  final DashboardService _dashboardService = DashboardService();

  final liveLocation = Rxn<LiveLocationModel>();
  var loading = false.obs;
  var hasFetched = false.obs;

  void getLiveLocation() async {
    loading.value = true;
    _dashboardService.getLiveLocation().then((response) {
      liveLocation.value = response.data;
      hasFetched.value = true;
      loading.value = false;
    }).onError((error, stackTrace) {
      hasFetched.value = true;
      loading.value = false;
    });
  }
}
