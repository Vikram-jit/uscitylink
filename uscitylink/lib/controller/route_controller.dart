import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/google_map_controller.dart';
import 'package:uscitylink/controller/station_controller.dart';
import 'package:uscitylink/model/route_model.dart';
import 'package:uscitylink/model/vehicle_gps_model.dart';
import 'package:uscitylink/services/document_service.dart';

class RouteController extends GetxController {
  var isLoading = false.obs;
  var routes = <RouteModel>[].obs;
  var nearByStations = <Stations>[].obs;
  var groupedStations = <StationGroup>[].obs; // Add this
  Rxn<VehicleGpsModel> truckLocation = Rxn<VehicleGpsModel>();
  GoogleMapController googleMapController = Get.put(GoogleMapController());
  late final StationController stationController; // Add this
  @override
  void onInit() {
    super.onInit();
    stationController = Get.put(StationController()); // Initialize

    fetchRoutes();
  }

  void _groupNearbyStations() {
    if (nearByStations.isNotEmpty) {
      // This now works because both controllers use the same StationGroup
      groupedStations.value =
          stationController.groupStationsByState(nearByStations);

      for (var group in groupedStations) {
        print('📍 ${group.stateName}: ${group.stationCount} stations');
      }
    }
  }

  Future<void> fetchRoutes() async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      var response = await DocumentService().getRoutes();

      // Check if the response is valid
      if (response.status == true) {
        routes.clear();
        // Append new trucks to the list
        routes.addAll(response.data);
        if (response.status) {
          if (response.data.length > 0) {
            await dotenv.load();
            String googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
            String samasaraKey = dotenv.env['SAMASARA_KEY'] ?? '';

            if (googleApiKey.isEmpty) {
              throw Exception('Google Maps API key not found');
            }
            if (samasaraKey.isEmpty) {
              throw Exception('Samasara  API key not found');
            }
            String truckId = response.data[0].truck?.samsara_vehicle_id ?? "";
            List<TruckWithNearbyStations> truckWithNearbyStations =
                await googleMapController.getTrucksWithNearbyStations(
                    vehicleIds: [truckId],
                    apiToken: samasaraKey,
                    googleApiKey: googleApiKey,
                    stations: response.data[0].stations ?? [],
                    destinationLat: response.data[0].toLat!,
                    destinationLng: response.data[0].toLng!);
            if (truckWithNearbyStations.isNotEmpty) {
              // Clear existing stations and add new ones
              nearByStations.clear();
              truckLocation.value = truckWithNearbyStations[0].truck;
              // Add all nearby stations from the first truck
              // Fixed: nearbyStations is already a List<Stations>
              nearByStations.addAll(truckWithNearbyStations[0].nearbyStations);
              _groupNearbyStations();
              print('✅ Found ${nearByStations.length} nearby stations');
            } else {
              print('⚠️ No truck ID found for route');
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching routes: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
