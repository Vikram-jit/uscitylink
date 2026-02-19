import 'dart:convert';
import 'dart:math';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uscitylink/model/route_model.dart';
import 'package:uscitylink/model/vehicle_gps_model.dart';

class TruckWithNearbyStations {
  final VehicleGpsModel truck;
  final List<Stations> nearbyStations;
  final String routeDistance;
  final String routeDuration;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;

  TruckWithNearbyStations({
    required this.truck,
    required this.nearbyStations,
    required this.routeDistance,
    required this.routeDuration,
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
  });
}

class GoogleMapController extends GetxController {
  GoogleMapController();

  final fromLocation = Rxn<LatLng>();
  final toLocation = Rxn<LatLng>();
  final allStations = <Stations>[].obs;

  final filteredStations = <Stations>[].obs;
  final routePath = <LatLng>[].obs;

  final routeDistance = ''.obs;
  final routeDuration = ''.obs;

  final isLoading = false.obs;
  final error = ''.obs;
  final stationCount = 0.obs;

  final maxDistanceMiles = 30.0.obs;

  // Get live truck locations and filter stations for each truck
  Future<List<TruckWithNearbyStations>> getTrucksWithNearbyStations({
    required List<String> vehicleIds,
    required String apiToken,
    required String googleApiKey,
    required List<Stations> stations,
    required double destinationLat,
    required double destinationLng,
    double maxMiles = 30.0,
  }) async {
    final List<TruckWithNearbyStations> results = [];

    try {
      isLoading.value = true;
      error.value = '';

      final trucks = await _fetchLiveTruckLocations(
        vehicleIds: vehicleIds,
        apiToken: apiToken,
      );

      for (var truck in trucks) {
        fromLocation.value = LatLng(truck.latitude, truck.longitude);
        toLocation.value = LatLng(destinationLat, destinationLng);
        allStations.value = stations;
        maxDistanceMiles.value = maxMiles;

        await _fetchRoute(truck.latitude, truck.longitude, destinationLat,
            destinationLng, googleApiKey);

        _performFiltering();

        // Get filtered stations
        final nearbyStations = filteredStations.toList();

        results.add(TruckWithNearbyStations(
          truck: truck,
          nearbyStations: nearbyStations,
          routeDistance: routeDistance.value,
          routeDuration: routeDuration.value,
          fromLat: truck.latitude,
          fromLng: truck.longitude,
          toLat: destinationLat,
          toLng: destinationLng,
        ));

        print('🚚 Truck ${truck.vehicleName}:');
        print('   Location: ${truck.latitude}, ${truck.longitude}');
        print('   Nearby stations: ${nearbyStations.length}');
        print('   Route: ${routeDistance.value} - ${routeDuration.value}');
      }
    } catch (e) {
      error.value = 'Error: $e';
      print('❌ $error');
    } finally {
      isLoading.value = false;
    }
    for (var result in results) {
      print('Truck: ${result.truck.vehicleName}');
      print('Current Location: ${result.fromLat}, ${result.fromLng}');
      print('Destination: ${result.toLat}, ${result.toLng}');
      print('Route: ${result.routeDistance} - ${result.routeDuration}');
      print('Nearby Stations: ${result.nearbyStations.length}');

      for (var station in result.nearbyStations) {
        print(
            '  - ${station.name} at ${station.latitude}, ${station.longitude}');
      }
    }
    return results;
  }

  // Private method to fetch live truck locations
  Future<List<VehicleGpsModel>> _fetchLiveTruckLocations({
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

  Future<void> _fetchRoute(double fromLat, double fromLng, double toLat,
      double toLng, String googleApiKey) async {
    final url = "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=$fromLat,$fromLng"
        "&destination=$toLat,$toLng"
        "&mode=driving"
        "&key=$googleApiKey";

    print('📡 Fetching route...');
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['status'] != 'OK') {
      throw Exception('Route not found: ${data['status']}');
    }

    // Store route distance and duration
    final leg = data['routes'][0]['legs'][0];
    routeDistance.value = leg['distance']['text'];
    routeDuration.value = leg['duration']['text'];

    // Decode polyline
    final points = PolylinePoints.decodePolyline(
        data['routes'][0]['overview_polyline']['points']);

    routePath.value =
        points.map((p) => LatLng(p.latitude, p.longitude)).toList();

    print('✅ Route found: ${routeDistance.value} - ${routeDuration.value}');
  }

  void _performFiltering() {
    if (routePath.isEmpty || allStations.isEmpty) {
      filteredStations.clear();
      stationCount.value = 0;
      return;
    }

    final maxMeters = maxDistanceMiles.value * 1609.34;
    final List<StationWithDistance> stationsWithDistance = [];

    for (var station in allStations) {
      final point = LatLng(station.latitude ?? 0, station.longitude ?? 0);
      final distanceMeters = _minDistanceToRoute(point);
      final distanceMiles = distanceMeters / 1609.34;

      if (distanceMeters <= maxMeters) {
        stationsWithDistance.add(StationWithDistance(
          station: station,
          distanceMiles: distanceMiles,
        ));
      }
    }

    stationsWithDistance
        .sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));

    filteredStations.value =
        stationsWithDistance.map((s) => s.station).toList();
    stationCount.value = filteredStations.length;
  }

  double _minDistanceToRoute(LatLng point) {
    if (routePath.isEmpty) return double.infinity;

    double minDist = double.infinity;

    for (int i = 0; i < routePath.length - 1; i++) {
      final dist = _distanceToSegment(point, routePath[i], routePath[i + 1]);
      if (dist < minDist) minDist = dist;
    }

    return minDist;
  }

  double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final lat1 = a.latitude;
    final lon1 = a.longitude;
    final lat2 = b.latitude;
    final lon2 = b.longitude;
    final plat = p.latitude;
    final plon = p.longitude;

    final double metersPerDegreeLat = 111320;
    final double metersPerDegreeLon = 111320 * cos(a.latitude * pi / 180);

    final x1 = lon1 * metersPerDegreeLon;
    final y1 = lat1 * metersPerDegreeLat;
    final x2 = lon2 * metersPerDegreeLon;
    final y2 = lat2 * metersPerDegreeLat;
    final px = plon * metersPerDegreeLon;
    final py = plat * metersPerDegreeLat;

    final distToA = sqrt(pow(px - x1, 2) + pow(py - y1, 2));
    final distToB = sqrt(pow(px - x2, 2) + pow(py - y2, 2));

    return distToA < distToB ? distToA : distToB;
  }

  void clear() {
    filteredStations.clear();
    allStations.clear();
    routePath.clear();
    fromLocation.value = null;
    toLocation.value = null;
    error.value = '';
    stationCount.value = 0;
    routeDistance.value = '';
    routeDuration.value = '';
  }
}

class StationWithDistance {
  final Stations station;
  final double distanceMiles;

  StationWithDistance({
    required this.station,
    required this.distanceMiles,
  });
}
