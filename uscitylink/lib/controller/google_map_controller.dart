import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uscitylink/model/vehicle_gps_model.dart';

/// Direct client-side Samsara GPS fetch — the only piece of this controller
/// still needed once fuel-station search moved from "stations along a
/// route" to "stations near the truck's current location" (server-side
/// radius search). Everything else here used to filter a station list by
/// proximity to a Google-Directions polyline between the truck and a route
/// endpoint; that's now done by the server against lat/lng directly, so it
/// was removed rather than left as dead code.
class GoogleMapController extends GetxController {
  GoogleMapController();

  Future<List<VehicleGpsModel>> fetchLiveTruckLocations({
    required List<String> vehicleIds,
    required String apiToken,
  }) async {
    final List<VehicleGpsModel> gpsDataList = [];

    final idsParam = vehicleIds.join(',');
    final url = Uri.parse(
      'https://api.samsara.com/fleet/vehicles/stats?vehicleIds=$idsParam&types=gps,fuelPercents',
    );

    print('📍 Fetching live truck locations for IDs: $idsParam');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List<dynamic> vehiclesData = jsonResponse['data'] ?? [];

      for (var vehicleJson in vehiclesData) {
        gpsDataList.add(VehicleGpsModel.fromJson(vehicleJson));
      }

      print('✅ Successfully fetched data for ${gpsDataList.length} vehicles.');
    } else {
      throw Exception(
        'Failed to fetch vehicle stats. Status Code: ${response.statusCode}. Body: ${response.body}',
      );
    }

    return gpsDataList;
  }
}
