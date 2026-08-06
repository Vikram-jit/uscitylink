import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/route_controller.dart';
import 'package:uscitylink/controller/station_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/driver/views/fuel_stations/widgets/station_map.dart';
import 'package:uscitylink/views/driver/views/fuel_stations/widgets/station_widget.dart';
import 'package:uscitylink/views/driver/views/fuel_stations/widgets/truck_info_widget.dart';

class FuelStationsView extends StatefulWidget {
  const FuelStationsView({
    Key? key,
  }) : super(key: key);

  @override
  State<FuelStationsView> createState() => _FuelStationsViewState();
}

class _FuelStationsViewState extends State<FuelStationsView> {
  late RouteController routeController;
  late StationController stationController;
  bool _isInitialized = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize RouteController
    if (Get.isRegistered<RouteController>()) {
      routeController = Get.find<RouteController>();
    } else {
      routeController = Get.put(RouteController(), permanent: true);
    }

    // Initialize StationController
    if (Get.isRegistered<StationController>()) {
      stationController = Get.find<StationController>();
    } else {
      stationController = Get.put(StationController(), permanent: true);
    }

    // Load data after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized && !_isLoadingData) {
        _loadInitialData();
      }
    });
  }

  Future<void> _loadInitialData() async {
    if (_isLoadingData) return;

    _isLoadingData = true;

    try {
      if (!mounted) return;
      await routeController.fetchNearbyStations();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error loading nearby stations: $e');
    } finally {
      _isLoadingData = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text(
            'Fuel Stations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: true,
          backgroundColor: TColors.navyHeader,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Obx(
      () {
        // Show loading indicator only when actually loading and no data
        if (routeController.isLoading.value &&
            routeController.nearByStations.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: TColors.navyHeader),
          );
        }

        // Show empty state if no nearby stations
        if (routeController.nearByStations.isEmpty) {
          return _buildEmptyState();
        }

        // Show content
        return _buildContent();
      },
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildMapPreview(),
          const SizedBox(height: 16),
          Obx(
            () => Container(
              key: ValueKey(
                  'truck_info_${routeController.truckLocation.value?.vehicleId ?? ''}'),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: const TruckInfoWidget(),
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Container(
              key:
                  ValueKey('stations_${routeController.nearByStations.length}'),
              child: routeController.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : StationWidget(), // This widget uses StationController internally
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_gas_station_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Stations Found Nearby',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadInitialData(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.navyHeader,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.map_rounded, color: TColors.navyHeader),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Map',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                color: Colors.grey[100],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.map,
                      size: 50,
                      color: Colors.grey[400],
                    ),
                  ),
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StationMapScreen(),
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: TColors.navyHeader,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.map,
                                          color: Colors.white),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'View Live Map',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Obx(
                                  () => Text(
                                    '${routeController.nearByStations.length} stations nearby',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isLoadingData = false;
    // Don't delete controllers if they're permanent
    if (Get.isRegistered<RouteController>()) {
      Get.delete<RouteController>(force: true);
    }

    if (Get.isRegistered<StationController>()) {
      Get.delete<StationController>(force: true);
    }
    super.dispose();
  }
}
