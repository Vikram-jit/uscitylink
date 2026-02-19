import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/route_controller.dart';
import 'package:uscitylink/controller/station_controller.dart'; // Add this import
import 'package:uscitylink/model/route_model.dart';
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
  late StationController stationController; // Add station controller
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
      await routeController.fetchRoutes();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error loading routes: $e');
    } finally {
      _isLoadingData = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Route Information'),
        backgroundColor: TColors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Obx(
      () {
        // Show loading indicator only when actually loading and no data
        if (routeController.isLoading.value && routeController.routes.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Show empty state if no routes
        if (routeController.routes.isEmpty) {
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
        children: routeController.routes.map((route) {
          return _buildRouteSection(route);
        }).toList(),
      ),
    );
  }

  Widget _buildRouteSection(RouteModel route) {
    return Column(
      key: ValueKey('route_section_${route.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRouteHeader(route),
        const SizedBox(height: 16),
        _buildMapPreview(route),
        const SizedBox(height: 16),
        // Use Obx with unique tag to prevent rebuild conflicts
        Obx(
          () => Container(
            key: ValueKey(
                'truck_info_${route.id}_${routeController.truckLocation.value?.vehicleId ?? ''}'),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: const TruckInfoWidget(),
          ),
        ),
        const SizedBox(height: 16),
        // Use Obx with unique tag
        Obx(
          () => Container(
            key: ValueKey(
                'stations_${route.id}_${routeController.nearByStations.length}'),
            child:
                StationWidget(), // This widget uses StationController internally
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Routes Available',
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
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteHeader(RouteModel route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${route.fromCity} → ${route.toCity ?? route.toAddress?.split(',')[0]}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Distance: ${route.distance} miles',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ID: ${route.id}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  route.fromAddress ?? "",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.flag, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  route.toAddress ?? "",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview(RouteModel route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.map, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Route Map',
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
                              builder: (context) => StationMapScreen(
                                routeData: route,
                              ),
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
                                    color: Colors.blue[700],
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.map,
                                          color: Colors.white),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'View Interactive Map',
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
                                    '${routeController.nearByStations.length} stations on map',
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
    // Get.delete<RouteController>();
    // Get.delete<StationController>();
    super.dispose();
  }
}
