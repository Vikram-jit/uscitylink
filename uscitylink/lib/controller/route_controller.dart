import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/google_map_controller.dart';
import 'package:uscitylink/controller/station_controller.dart';
import 'package:uscitylink/model/lat_lng_model.dart';
import 'package:uscitylink/model/route_model.dart';
import 'package:uscitylink/model/vehicle_gps_model.dart';
import 'package:uscitylink/services/document_service.dart';

/// Fuel stations near the driver's truck's current location — the truck's
/// live GPS is fetched from Samsara client-side (unchanged, pre-existing
/// pattern), then sent to `GET /yard/stations/nearby` for a radius search.
/// There is no "route" concept here: no from/to, no swap direction, no
/// Google Directions polyline — just distance from wherever the truck is
/// right now.
class RouteController extends GetxController {
  var isLoading = false.obs;
  var nearByStations = <Stations>[].obs;
  var groupedStations = <StationGroup>[].obs;
  Rxn<VehicleGpsModel> truckLocation = Rxn<VehicleGpsModel>();

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
        fetchNearbyStations();
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
      fetchNearbyStations();
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
      _metadataBox = await Hive.openBox<int>('metadata_box');

      print('✅ Hive boxes initialized successfully');
    } catch (e) {
      print('❌ Error initializing Hive boxes: $e');
      _truckBox = await Hive.openBox<VehicleGpsModel>('truck_fallback');
      _stationsBox = await Hive.openBox<Stations>('stations_fallback');
      _lastUpdatedBox = await Hive.openBox<DateTime>('last_updated_fallback');
      _metadataBox = await Hive.openBox<int>('metadata_fallback');
    }
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
    if (nearByStations.isEmpty &&
        _stationsBox.isOpen &&
        _stationsBox.isNotEmpty) {
      _loadCachedData();
    }

    if (truckLocation.value == null &&
        _truckBox.isOpen &&
        _truckBox.containsKey('current')) {
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
    // Check if the box is open before accessing it — checking the held box
    // instance's own `.isOpen` reflects whether *this* reference is still
    // usable, unlike a name-based `Hive.isBoxOpen()` lookup.
    if (_truckBox.isOpen) {
      if (_truckBox.containsKey('current')) {
        final cachedTruck = _truckBox.get('current');
        if (cachedTruck != null) {
          truckLocation.value = cachedTruck;
          print('📦 Loaded cached truck location');
        }
      }
    }

    /// Stations
    if (_stationsBox.isOpen) {
      final loadedStations = _loadStationsList();
      if (loadedStations.isNotEmpty) {
        nearByStations.value = loadedStations;
        _groupNearbyStations();
        print('📦 Loaded ${loadedStations.length} cached stations');
      }
    }
  }

  void _setupPeriodicUpdates() {
    _truckUpdateTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (Get.isRegistered<RouteController>() && !isOffline.value) {
        print('🔄 Periodic truck location update');
        _refreshTruckLocation();
      }
    });

    _stationsUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (Get.isRegistered<RouteController>() && !isOffline.value) {
        print('🔄 Periodic stations update');
        fetchNearbyStations(isPeriodic: true);
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

  Future<void> fetchNearbyStations({bool isPeriodic = false}) async {
    // Check if offline
    if (isOffline.value) {
      print('📴 Offline - using cached data');
      _ensureCachedDataLoaded();
      return;
    }

    if (isLoading.value) return;
    isLoading.value = true;

    try {
      final truckResponse = await DocumentService().getMyTruck();
      final myTruck = truckResponse.data;

      if (myTruck?.samsaraVehicleId == null ||
          myTruck!.samsaraVehicleId!.isEmpty) {
        throw Exception('No truck assigned, or truck has no Samsara id');
      }

      await dotenv.load();
      String samasaraKey = dotenv.env['SAMASARA_KEY'] ?? '';

      if (samasaraKey.isEmpty) {
        throw Exception('Samasara API key not found');
      }

      // Always fetch fresh truck location when online — same direct Samsara
      // call as before, unchanged.
      List<VehicleGpsModel> truckLocations =
          await googleMapController.fetchLiveTruckLocations(
        vehicleIds: [myTruck.samsaraVehicleId!],
        apiToken: samasaraKey,
      );

      if (truckLocations.isEmpty) {
        throw Exception('No live location returned for this truck');
      }

      truckLocation.value = truckLocations[0];
      await _truckBox.put('current', truckLocation.value!);
      await _updateLastUpdated('truck');

      // Stations near the truck's current position — server-side radius
      // search + distance, no route involved.
      final stationsResponse = await DocumentService().getNearbyStations(
        lat: truckLocation.value!.latitude,
        lng: truckLocation.value!.longitude,
      );

      nearByStations.clear();
      nearByStations.addAll(stationsResponse.data);

      if (nearByStations.isNotEmpty) {
        await _saveStationsList(nearByStations.toList());
        await _updateLastUpdated('stations');
      }

      _groupNearbyStations();

      await findAndMarkRecommendedStations(
        stateGroups: groupedStations,
        truckFuelPercent: truckLocation.value?.fuelPercent ?? 0,
      );

      print('✅ Found ${nearByStations.length} nearby stations');
    } catch (e) {
      print(e);
      _ensureCachedDataLoaded();
    } finally {
      isLoading.value = false;
    }
  }

  Future<LatLng?> getTuckLocation({bool forceRefresh = false}) async {
    // Check if offline
    if (isOffline.value) {
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
      final truckResponse = await DocumentService().getMyTruck();
      final myTruck = truckResponse.data;

      await dotenv.load();
      String samasaraKey = dotenv.env['SAMASARA_KEY'] ?? '';

      if (samasaraKey.isEmpty || myTruck?.samsaraVehicleId == null) {
        throw Exception('Samasara API key or truck id not found');
      }

      List<VehicleGpsModel> truckLocations = await googleMapController
          .fetchLiveTruckLocations(
              vehicleIds: [myTruck!.samsaraVehicleId!], apiToken: samasaraKey);

      if (truckLocations.isNotEmpty) {
        // Cache the fresh data
        await _truckBox.put('current', truckLocations[0]);
        await _updateLastUpdated('truck');

        print('✅ Fresh truck location fetched');
        return LatLng(truckLocations[0].latitude, truckLocations[0].longitude);
      }
    } catch (e) {
      print("Error fetching truck location: $e");

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
    await fetchNearbyStations(isPeriodic: true);
  }

  @override
  void onClose() {
    _truckUpdateTimer?.cancel();
    _stationsUpdateTimer?.cancel();
    _connectivitySubscription.cancel();
    super.onClose();
  }

  /// Ranks stations within each state group by the driver's fuel level —
  /// ≤30% fuel flags the nearest station per state, 30–50% flags the
  /// cheapest per state — and sorts accordingly. `distanceFromTruck` is
  /// already populated by `Stations.fromJson` from the server's
  /// `distance_miles`, so there's no distance calculation here anymore —
  /// this used to also rank by proximity to a route polyline
  /// (`distanceFromRoute`/`isRecommended`), which no longer exists now that
  /// stations are found by truck location instead of a predefined route.
  Future<void> findAndMarkRecommendedStations({
    required List<StationGroup> stateGroups,
    required int? truckFuelPercent,
  }) async {
    try {
      isLoading.value = true;

      final allStations = stateGroups.expand((g) => g.stations).toList();

      // 🔹 Reset flags
      for (var station in allStations) {
        station.isCheapestInState = false;
        station.isNearestStation = false;
      }

      // =========================================================
      // 🔴 CASE 1: Fuel ≤ 30% → NEAREST PER STATE
      // =========================================================
      if (truckFuelPercent != null && truckFuelPercent <= 30) {
        for (var group in stateGroups) {
          if (group.stations.isEmpty) continue;

          Stations? nearest;
          double nearestDistance = double.infinity;

          for (var station in group.stations) {
            if (station.distanceFromTruck != null &&
                station.distanceFromTruck! < nearestDistance) {
              nearestDistance = station.distanceFromTruck!;
              nearest = station;
            }
          }

          if (nearest != null) {
            nearest.isNearestStation = true;
          }
        }
      }

      // =========================================================
      // 🟡 CASE 2: 30% < Fuel < 50% → CHEAPEST PER STATE
      // =========================================================
      else if (truckFuelPercent != null &&
          truckFuelPercent > 30 &&
          truckFuelPercent < 50) {
        for (var group in stateGroups) {
          if (group.stations.isEmpty) continue;

          Stations? cheapest;
          double? lowestPrice;

          for (var station in group.stations) {
            final price = double.tryParse(station.fuelPrice?.yourPrice ?? '');
            if (price != null) {
              if (lowestPrice == null || price < lowestPrice) {
                lowestPrice = price;
                cheapest = station;
              }
            }
          }

          if (cheapest != null) {
            cheapest.isCheapestInState = true;
          }
        }
      }

      // =========================================================
      // 🔹 Min distance per state (drives state sort order)
      // =========================================================
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

      stateGroups.sort((a, b) => (a.minDistanceFromTruck ?? double.infinity)
          .compareTo(b.minDistanceFromTruck ?? double.infinity));

      // =========================================================
      // 🔹 Sort stations inside each state
      // =========================================================
      for (var group in stateGroups) {
        group.stations.sort((a, b) {
          // 🔴 Fuel ≤ 30 → nearest per state first
          if (truckFuelPercent != null && truckFuelPercent <= 30) {
            if (a.isNearestStation == true && b.isNearestStation != true) {
              return -1;
            }
            if (a.isNearestStation != true && b.isNearestStation == true) {
              return 1;
            }
          }

          // 🟡 Fuel 30–50 → cheapest first
          if (truckFuelPercent != null &&
              truckFuelPercent > 30 &&
              truckFuelPercent < 50) {
            if (a.isCheapestInState == true && b.isCheapestInState != true) {
              return -1;
            }
            if (a.isCheapestInState != true && b.isCheapestInState == true) {
              return 1;
            }
          }

          // 💰 Default price sorting
          final priceA = double.tryParse(a.fuelPrice?.yourPrice ?? '');
          final priceB = double.tryParse(b.fuelPrice?.yourPrice ?? '');

          if (priceA != null && priceB != null) {
            return priceA.compareTo(priceB);
          }

          if (priceA != null) return -1;
          if (priceB != null) return 1;

          // 📍 Distance fallback
          return (a.distanceFromTruck ?? double.infinity)
              .compareTo(b.distanceFromTruck ?? double.infinity);
        });
      }

      update();
    } catch (e) {
      print('❌ Error finding recommendations: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
