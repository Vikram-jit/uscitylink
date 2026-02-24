import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
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
  var groupedStations = <StationGroup>[].obs;
  Rxn<VehicleGpsModel> truckLocation = Rxn<VehicleGpsModel>();

  var isRouteSwapped = false.obs;
  // Offline status
  var isOffline = false.obs;
  var hasCachedData = false.obs;

  late GoogleMapController googleMapController;
  late StationController stationController;

  // Hive boxes
  late Box<int> _metadataBox;

  late Box<VehicleGpsModel> _truckBox;
  late Box<Stations> _stationsBox;
  late Box<DateTime> _lastUpdatedBox;
  late Box<dynamic> _prefsBox;
  late Box<List> _routesBox;

  // Timers for periodic updates
  Timer? _truckUpdateTimer;
  Timer? _stationsUpdateTimer;

  // Connectivity
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _initControllers();
    _initConnectivity();
    _initializeApp();
  }

// Add this method to save swapped state
  Future<void> _saveSwappedState() async {
    try {
      await _prefsBox.put('isSwapped', isRouteSwapped.value);
      print('💾 Saved swapped state: ${isRouteSwapped.value}');
    } catch (e) {
      print('❌ Error saving swapped state: $e');
    }
  }

  Future<void> _loadSwappedState() async {
    try {
      if (_prefsBox.containsKey('isSwapped')) {
        isRouteSwapped.value = _prefsBox.get('isSwapped') as bool;
        print('📦 Loaded swapped state: ${isRouteSwapped.value}');
      }
    } catch (e) {
      print('❌ Error loading swapped state: $e');
    }
  }

  void _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);

      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    } catch (e) {
      print('Error initializing connectivity: $e');
      isOffline.value = true;
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final wasOffline = isOffline.value;
    final isConnected =
        result.isNotEmpty && !result.contains(ConnectivityResult.none);
    isOffline.value = !isConnected;

    if (isConnected) {
      print('📶 Internet connected');
      if (wasOffline) {
        print('🔄 Refreshing data after coming online');
        fetchRoutes();
      }
    } else {
      print('📴 Internet disconnected');
      _showOfflineData();
    }
  }

  Future<void> _initializeApp() async {
    await _initHiveBoxes();
    _loadCachedData();
    _setupPeriodicUpdates();

    hasCachedData.value =
        _truckBox.containsKey('current') || _stationsBox.isNotEmpty;

    if (!isOffline.value) {
      fetchRoutes();
    } else {
      _showOfflineData();
    }
  }

  void _initControllers() {
    googleMapController = Get.put(GoogleMapController());
    stationController = Get.put(StationController());
  }

  Future<void> _initHiveBoxes() async {
    try {
      _truckBox = await Constant.getTruckLocationBox();
      _stationsBox = await Constant.getStationsBox();
      _lastUpdatedBox = await Constant.getlastUpdatedBox();
      _prefsBox = await Hive.openBox<dynamic>('prefs_box');
      _routesBox = await Hive.openBox<List>('routes_box');
      _metadataBox = await Hive.openBox<int>('metadata_box');

      await _loadSwappedState();
      print('✅ Hive boxes initialized successfully');
    } catch (e) {
      print('❌ Error initializing Hive boxes: $e');
      _truckBox = await Hive.openBox<VehicleGpsModel>('truck_fallback');
      _stationsBox = await Hive.openBox<Stations>('stations_fallback');
      _lastUpdatedBox = await Hive.openBox<DateTime>('last_updated_fallback');
      _prefsBox = await Hive.openBox<dynamic>('prefs_fallback');
      _routesBox = await Hive.openBox<List>('routes_fallback');
      _metadataBox = await Hive.openBox<int>('metadata_fallback');
    }
  }

  void toggleSwap() {
    isRouteSwapped.value = !isRouteSwapped.value;
    _saveSwappedState();
    print('🔄 Swap toggled: ${isRouteSwapped.value}');

    update();
  }

  void resetSwap() {
    isRouteSwapped.value = false;
    _saveSwappedState();
    print('🔄 Swap reset to false');
    update();
  }

  void _showOfflineData() {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        'Offline Mode',
        'Showing cached data. Connect to internet for live updates.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }

    _ensureCachedDataLoaded();
  }

  void _ensureCachedDataLoaded() {
    if (nearByStations.isEmpty && _stationsBox.isNotEmpty) {
      _loadCachedData();
    }

    if (truckLocation.value == null && _truckBox.containsKey('current')) {
      _loadCachedData();
    }
  }

  // New method to save multiple stations
  Future<void> _saveStationsList(List<Stations> stations) async {
    try {
      // Clear existing stations
      await _stationsBox.clear();

      // Save each station with index key
      for (int i = 0; i < stations.length; i++) {
        await _stationsBox.put('station_$i', stations[i]);
      }

      // Save the count
      await _metadataBox.put('station_count', stations.length);
      print('💾 Saved ${stations.length} stations to Hive');
    } catch (e) {
      print('❌ Error saving stations: $e');
    }
  }

  // New method to load multiple stations
  List<Stations> _loadStationsList() {
    List<Stations> stations = [];
    try {
      final count = _metadataBox.get('station_count', defaultValue: 0) ?? 0;
      for (int i = 0; i < count; i++) {
        final station = _stationsBox.get('station_$i');
        if (station != null) {
          stations.add(station);
        }
      }
      print('📦 Loaded ${stations.length} stations from Hive');
    } catch (e) {
      print('❌ Error loading stations: $e');
    }
    return stations;
  }

  void _loadCachedData() {
    // Load cached truck
    if (_truckBox.containsKey('current')) {
      final cachedTruck = _truckBox.get('current');
      if (cachedTruck != null) {
        truckLocation.value = cachedTruck;
        print('📦 Loaded cached truck location');
      }
    }

    // Load cached stations using the new method
    final loadedStations = _loadStationsList();
    if (loadedStations.isNotEmpty) {
      nearByStations.value = loadedStations;
      _groupNearbyStations();
      print('📦 Loaded ${loadedStations.length} cached stations');
    }

    // Load cached routes
    if (_routesBox.containsKey('routes')) {
      final cachedRoutes = _routesBox.get('routes');
      if (cachedRoutes != null) {
        routes.value = cachedRoutes.cast<RouteModel>();
        print('📦 Loaded ${routes.length} cached routes');
      }
    }
  }

  Future<void> _cacheRoutes() async {
    await _routesBox.put('routes', routes.toList());
  }

  void _setupPeriodicUpdates() {
    _truckUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (Get.isRegistered<RouteController>() && !isOffline.value) {
        print('🔄 Periodic truck location update');
        _refreshTruckLocation();
      }
    });

    _stationsUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (Get.isRegistered<RouteController>() && !isOffline.value) {
        print('🔄 Periodic stations update');
        fetchRoutes(isPeriodic: true);
      }
    });
  }

  Future<void> _updateLastUpdated(String key) async {
    await _lastUpdatedBox.put(key, DateTime.now());
  }

  void _groupNearbyStations() {
    if (nearByStations.isNotEmpty) {
      groupedStations.value =
          stationController.groupStationsByState(nearByStations);
      print(
          '📍 Grouped ${nearByStations.length} stations into ${groupedStations.length} states');
      for (var group in groupedStations) {
        print('📍 ${group.stateName}: ${group.stationCount} stations');
      }
    } else {
      print('⚠️ No nearby stations to group');
      groupedStations.clear();
    }
  }

  Future<void> fetchRoutes({bool isPeriodic = false}) async {
    // Check if offline
    if (isOffline.value) {
      print('📴 Offline - using cached data');
      _ensureCachedDataLoaded();
      return;
    }

    // For periodic updates or any online fetch, ALWAYS get fresh data
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      print('🌐 Fetching fresh routes from API...');
      var response = await DocumentService().getRoutes();

      if (response.status == true) {
        routes.clear();
        routes.addAll(response.data);

        // Cache the fresh data
        await _cacheRoutes();

        if (response.data.isNotEmpty) {
          await dotenv.load();
          String googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
          String samasaraKey = dotenv.env['SAMASARA_KEY'] ?? '';

          if (googleApiKey.isEmpty || samasaraKey.isEmpty) {
            throw Exception('API keys not found');
          }

          String truckId = response.data[0].truck?.samsara_vehicle_id ?? "";

          // Always fetch fresh truck location when online
          print('🔄 Fetching fresh truck location...');
          List<TruckWithNearbyStations> truckWithNearbyStations =
              await googleMapController.getTrucksWithNearbyStations(
                  vehicleIds: [truckId],
                  apiToken: samasaraKey,
                  googleApiKey: googleApiKey,
                  stations: response.data[0].stations ?? [],
                  destinationLat: isRouteSwapped.value
                      ? response.data[0].fromLat!
                      : response.data[0].toLat!,
                  destinationLng: isRouteSwapped.value
                      ? response.data[0].fromLng!
                      : response.data[0].toLng!);

          if (truckWithNearbyStations.isNotEmpty) {
            nearByStations.clear();
            truckLocation.value = truckWithNearbyStations[0].truck;

            if (truckLocation.value != null) {
              await _truckBox.put('current', truckLocation.value!);
              await _updateLastUpdated('truck');
            }

            nearByStations.addAll(truckWithNearbyStations[0].nearbyStations);

            // Save multiple stations using new method
            if (nearByStations.isNotEmpty) {
              await _saveStationsList(nearByStations.toList());
              await _updateLastUpdated('stations');
            }

            _groupNearbyStations();

            await findAndMarkRecommendedStations(
                truckLocation: LatLng(truckLocation.value?.latitude ?? 0,
                    truckLocation.value?.longitude ?? 0),
                destination: LatLng(
                    isRouteSwapped.value
                        ? response.data[0].fromLat ?? 0
                        : response.data[0].toLat ?? 0,
                    isRouteSwapped.value
                        ? response.data[0].fromLng ?? 0
                        : response.data[0].toLng ?? 0),
                stateGroups: groupedStations,
                googleApi: googleApiKey,
                radiusMiles: 100,
                truckFuelPercent: truckLocation.value?.fuelPercent ?? 0);

            print('✅ Found ${nearByStations.length} nearby stations');
          }
        }
      }
    } catch (e) {
      print("❌ Error fetching routes: $e");
      _ensureCachedDataLoaded();

      if (!Get.isSnackbarOpen) {
        Get.snackbar(
          'Connection Error',
          'Could not fetch fresh data. Showing cached version.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<LatLng?> getTuckLocation({bool forceRefresh = false}) async {
    // Check if offline
    if (isOffline.value) {
      print('📴 Offline - returning cached location');
      final cachedTruck = _truckBox.get('current');
      if (cachedTruck != null) {
        return LatLng(cachedTruck.latitude, cachedTruck.longitude);
      }
      return null;
    }

    // When online, always fetch fresh data - ignore cache
    if (isLoading.value) return null;
    isLoading.value = true;

    try {
      print('🌐 Fetching fresh truck location from API...');
      var response = await DocumentService().getRoutes();

      if (response.status == true && response.data.isNotEmpty) {
        await dotenv.load();
        String samasaraKey = dotenv.env['SAMASARA_KEY'] ?? '';

        if (samasaraKey.isEmpty) {
          throw Exception('Samasara API key not found');
        }

        String truckId = response.data[0].truck?.samsara_vehicle_id ?? "";

        List<VehicleGpsModel> truckLocations = await googleMapController
            .fetchLiveTruckLocations(
                vehicleIds: [truckId], apiToken: samasaraKey);

        if (truckLocations.isNotEmpty) {
          // Cache the fresh data
          await _truckBox.put('current', truckLocations[0]);
          await _updateLastUpdated('truck');

          print('✅ Fresh truck location fetched');
          return LatLng(
              truckLocations[0].latitude, truckLocations[0].longitude);
        }
      }
    } catch (e) {
      print("❌ Error fetching truck location: $e");

      // Only use cache on error
      final cachedTruck = _truckBox.get('current');
      if (cachedTruck != null) {
        print('📦 Returning cached truck location due to error');
        return LatLng(cachedTruck.latitude, cachedTruck.longitude);
      }
      return null;
    } finally {
      isLoading.value = false;
    }
    return null;
  }

// Update your periodic refresh method
  Future<void> _refreshTruckLocation() async {
    print('🔄 Periodic truck location update - fetching fresh data');
    await fetchRoutes(isPeriodic: true);
  }

  @override
  void onClose() {
    _truckUpdateTimer?.cancel();
    _stationsUpdateTimer?.cancel();
    _connectivitySubscription.cancel();
    super.onClose();
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
