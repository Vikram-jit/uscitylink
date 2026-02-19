import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/google_map_controller.dart';
import 'package:uscitylink/controller/station_controller.dart';
import 'package:uscitylink/model/lat_lng_model.dart';
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
  StationController stationController =
      Get.put(StationController()); // Add this
  @override
  void onInit() {
    super.onInit();

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
              await findAndMarkRecommendedStations(
                  truckLocation: LatLng(truckLocation.value?.latitude ?? 00,
                      truckLocation.value?.longitude ?? 00),
                  destination: LatLng(response.data[0].toLat ?? 00,
                      response.data[0].toLng ?? 00),
                  stateGroups: groupedStations,
                  googleApi: googleApiKey,
                  radiusMiles: 100,
                  truckFuelPercent: truckLocation.value?.fuelPercent ?? 00);
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

  Future<void> findAndMarkRecommendedStations({
    required LatLng truckLocation,
    required LatLng destination,
    required List<StationGroup> stateGroups,
    required String googleApi,
    double radiusMiles = 50.0,
    required int? truckFuelPercent,
  }) async {
    try {
      isLoading.value = true;

      final routePoints =
          await _getRoutePoints(truckLocation, destination, googleApi);
      print("✅ Route found with ${routePoints.length} points");

      final allStations = stateGroups.expand((g) => g.stations).toList();
      for (var station in allStations) {
        station.isRecommended = false;
        station.isCheapestInState = false;
        station.isNearestStation = false;
        station.isBothNearestAndCheapest = false;
      }

      int stationsNearRoute = 0;
      int stationsNearTruck = 0;

      for (var station in allStations) {
        final stationPoint = LatLng(
          station.latitude ?? 0,
          station.longitude ?? 0,
        );

        double minRouteDistance = double.infinity;
        for (var routePoint in routePoints) {
          final distance =
              _calculateDistance(stationPoint, routePoint) / 1609.34;
          if (distance < minRouteDistance) {
            minRouteDistance = distance;
          }
        }
        station.distanceFromRoute = minRouteDistance;

        station.distanceFromTruck =
            _calculateDistance(stationPoint, truckLocation) / 1609.34;

        if (minRouteDistance <= radiusMiles) {
          stationsNearRoute++;
          station.isRecommended = true;
        }
      }

      Stations? nearestStation;
      double nearestDistance = double.infinity;

      for (var station in allStations) {
        if (station.distanceFromTruck! < nearestDistance) {
          nearestDistance = station.distanceFromTruck!;
          nearestStation = station;
        }
      }

      for (var group in stateGroups) {
        if (group.stations.isEmpty) continue;

        Stations? cheapestInState;
        double? lowestPrice;

        for (var station in group.stations) {
          if (station.fuelPrice?.yourPrice != null) {
            final price = double.tryParse(station.fuelPrice!.yourPrice!);
            if (price != null) {
              if (lowestPrice == null || price < lowestPrice) {
                lowestPrice = price;
                cheapestInState = station;
              }
            }
          }
        }

        if (cheapestInState != null) {
          print(
              '   🏆 ${group.stateName} cheapest: ${cheapestInState.name} (ID: ${cheapestInState.id}) at \$${lowestPrice}');
        }
      }

      if (truckFuelPercent != null && truckFuelPercent <= 30) {
        if (nearestStation != null) {
          bool isNearestAlsoCheapest = false;

          final nearestState = nearestStation.state;
          final nearestStateGroup = stateGroups.firstWhere(
            (g) => g.stateCode == nearestState,
            orElse: () =>
                StationGroup(stateCode: '', stateName: '', stations: []),
          );

          if (nearestStateGroup.stations.isNotEmpty) {
            double? lowestPriceInState;
            Stations? cheapestInState;

            for (var station in nearestStateGroup.stations) {
              if (station.fuelPrice?.yourPrice != null) {
                final price = double.tryParse(station.fuelPrice!.yourPrice!);
                if (price != null) {
                  if (lowestPriceInState == null ||
                      price < lowestPriceInState) {
                    lowestPriceInState = price;
                    cheapestInState = station;
                  }
                }
              }
            }

            if (cheapestInState != null &&
                cheapestInState.id == nearestStation.id) {
              isNearestAlsoCheapest = true;
            }
          }
        }

        for (var group in stateGroups) {
          if (group.stations.isEmpty) continue;

          Stations? cheapestInState;
          double? lowestPrice;

          for (var station in group.stations) {
            if (station.fuelPrice?.yourPrice != null) {
              final price = double.tryParse(station.fuelPrice!.yourPrice!);
              if (price != null) {
                if (lowestPrice == null || price < lowestPrice) {
                  lowestPrice = price;
                  cheapestInState = station;
                }
              }
            }
          }

          if (cheapestInState != null) {
            if (nearestStation != null &&
                cheapestInState.id == nearestStation.id) {
              continue;
            }
            cheapestInState.isCheapestInState = true;
          }
        }
      } else if (truckFuelPercent != null && truckFuelPercent < 50) {
        for (var group in stateGroups) {
          if (group.stations.isEmpty) continue;

          Stations? cheapestInState;
          double? lowestPrice;

          for (var station in group.stations) {
            if (station.fuelPrice?.yourPrice != null) {
              final price = double.tryParse(station.fuelPrice!.yourPrice!);
              if (price != null) {
                if (lowestPrice == null || price < lowestPrice) {
                  lowestPrice = price;
                  cheapestInState = station;
                }
              }
            }
          }

          if (cheapestInState != null) {
            cheapestInState.isCheapestInState = true;
          }
        }
      }

      for (var group in stateGroups) {
        double minStateDistance = double.infinity;
        for (var station in group.stations) {
          if (station.distanceFromTruck != null &&
              station.distanceFromTruck! < minStateDistance) {
            minStateDistance = station.distanceFromTruck!;
          }
        }
        group.minDistanceFromTruck = minStateDistance;
      }

      stateGroups.sort((a, b) {
        final distA = a.minDistanceFromTruck ?? double.infinity;
        final distB = b.minDistanceFromTruck ?? double.infinity;
        return distA.compareTo(distB);
      });

      for (var group in stateGroups) {
        group.stations.sort((a, b) {
          if (truckFuelPercent != null && truckFuelPercent <= 30) {
            if (a.isBothNearestAndCheapest == true &&
                b.isBothNearestAndCheapest != true) return -1;
            if (a.isBothNearestAndCheapest != true &&
                b.isBothNearestAndCheapest == true) return 1;

            if (a.isNearestStation == true && b.isNearestStation != true)
              return -1;
            if (a.isNearestStation != true && b.isNearestStation == true)
              return 1;

            if (a.isCheapestInState == true && b.isCheapestInState != true)
              return -1;
            if (a.isCheapestInState != true && b.isCheapestInState == true)
              return 1;
          }

          if (truckFuelPercent != null &&
              truckFuelPercent < 50 &&
              truckFuelPercent > 30) {
            if (a.isCheapestInState == true && b.isCheapestInState != true)
              return -1;
            if (a.isCheapestInState != true && b.isCheapestInState == true)
              return 1;
          }

          final priceA = double.tryParse(a.fuelPrice?.yourPrice ?? '');
          final priceB = double.tryParse(b.fuelPrice?.yourPrice ?? '');

          if (priceA != null && priceB != null) {
            return priceA.compareTo(priceB);
          }

          if (priceA != null) return -1;
          if (priceB != null) return 1;

          return (a.distanceFromTruck ?? 0).compareTo(b.distanceFromTruck ?? 0);
        });
      }

      for (var group in stateGroups) {
        print('\n📍 ${group.stateName} (${group.stations.length} stations):');

        for (var station in group.stations) {
          final price = double.tryParse(station.fuelPrice?.yourPrice ?? '');
          final priceStr =
              price != null ? '\$${price.toStringAsFixed(2)}' : 'No price';

          String marker = '';
          if (station.isBothNearestAndCheapest == true) {
            marker = '⭐ ';
          } else if (station.isNearestStation == true) {
            marker = '🚨 ';
          } else if (station.isCheapestInState == true) {
            marker = '🏆 ';
          }

          final nearRoute = station.distanceFromRoute != null &&
                  station.distanceFromRoute! <= radiusMiles
              ? ' (Near Route)'
              : '';

          print(
              '   ${marker}${station.name} (ID: ${station.id}) - ${priceStr} - ${station.distanceFromTruck!.toStringAsFixed(1)} miles from truck${nearRoute}');
        }
      }

      update();
    } catch (e) {
      print('❌ Error finding recommendations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Get route polyline points
  Future<List<LatLng>> _getRoutePoints(
      LatLng origin, LatLng destination, String googleApiKey) async {
    final url = "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}"
        "&mode=driving"
        "&key=$googleApiKey";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['status'] != 'OK') {
      throw Exception('Route not found: ${data['status']}');
    }

    final points = PolylinePoints.decodePolyline(
        data['routes'][0]['overview_polyline']['points']);

    return points.map((p) => LatLng(p.latitude, p.longitude)).toList();
  }

  // Calculate distance between two points in meters
  double _calculateDistance(LatLng p1, LatLng p2) {
    const double R = 6371000; // Earth's radius in meters

    final dLat = _toRadians(p2.latitude - p1.latitude);
    final dLon = _toRadians(p2.longitude - p1.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(p1.latitude)) *
            cos(_toRadians(p2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * pi / 180;
}
