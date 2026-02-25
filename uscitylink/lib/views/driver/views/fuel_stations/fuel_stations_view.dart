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
            child: routeController.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : StationWidget(), // This widget uses StationController internally
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
    final RouteController routeController = Get.find<RouteController>();

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
          // Swap indicator and button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Swap status indicator
              Obx(() {
                if (routeController.isRouteSwapped.value) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz,
                            size: 14, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Swapped Direction',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Swap button
              Obx(() {
                if (routeController.routes.isNotEmpty) {
                  return Row(
                    children: [
                      if (routeController.isRouteSwapped.value)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.restore,
                                color: Colors.green.shade700, size: 18),
                            onPressed: () {
                              routeController.toggleSwap();
                            },
                            tooltip: 'Reset to original',
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          color: routeController.isRouteSwapped.value
                              ? Colors.blue.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.swap_horiz,
                            color: routeController.isRouteSwapped.value
                                ? Colors.blue.shade700
                                : Colors.grey.shade700,
                            size: 18,
                          ),
                          onPressed: () =>
                              _showSwapOptions(context, route, routeController),
                          tooltip: 'Swap route direction',
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),

          const SizedBox(height: 12),

          // Route info with swapped display
          Obx(() {
            final isSwapped = routeController.isRouteSwapped.value;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // From location with swap indicator
                      Row(
                        children: [
                          Text(
                            isSwapped ? 'FROM (Swapped)' : 'FROM',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSwapped ? Colors.blue : Colors.grey,
                              fontWeight:
                                  isSwapped ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          if (isSwapped) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.swap_vert, size: 12, color: Colors.blue),
                          ],
                        ],
                      ),
                      Text(
                        isSwapped
                            ? (route.toCity ??
                                route.toAddress?.split(',')[0] ??
                                'Destination')
                            : (route.fromCity ?? 'Origin'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSwapped ? Colors.blue[800] : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Distance: ${route.distance} miles',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow indicator
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    isSwapped ? Icons.arrow_back : Icons.arrow_forward,
                    color:
                        isSwapped ? Colors.blue.shade600 : Colors.grey.shade600,
                    size: 20,
                  ),
                ),

                // To location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isSwapped) ...[
                            Icon(Icons.swap_vert,
                                size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            isSwapped ? 'TO (Swapped)' : 'TO',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSwapped ? Colors.green : Colors.grey,
                              fontWeight:
                                  isSwapped ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isSwapped
                            ? (route.fromCity ?? 'Origin')
                            : (route.toCity ??
                                route.toAddress?.split(',')[0] ??
                                'Destination'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSwapped ? Colors.green[800] : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),

                // Route ID
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ID: ${route.id}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 16),

          // From address
          Obx(() {
            final isSwapped = routeController.isRouteSwapped.value;
            return Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: isSwapped ? Colors.blue[700] : Colors.blue[700],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSwapped
                        ? (route.toAddress ?? "")
                        : (route.fromAddress ?? ""),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 8),

          // To address
          Obx(() {
            final isSwapped = routeController.isRouteSwapped.value;
            return Row(
              children: [
                Icon(
                  Icons.flag,
                  color: isSwapped ? Colors.green[700] : Colors.green[700],
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSwapped
                        ? (route.fromAddress ?? "")
                        : (route.toAddress ?? ""),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

// Helper method to show swap options
  void _showSwapOptions(
      BuildContext context, RouteModel route, RouteController controller) {
    final isSwapped = controller.isRouteSwapped.value;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Direction',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Current direction
            _buildDirectionOption(
              title: 'Current Direction',
              from: isSwapped
                  ? route.toCity ?? 'Destination'
                  : route.fromCity ?? 'Origin',
              to: isSwapped
                  ? route.fromCity ?? 'Origin'
                  : route.toCity ?? 'Destination',
              isActive: true,
              onTap: () {
                Get.back();
                controller.toggleSwap();
              },
            ),

            const SizedBox(height: 12),

            // Swapped direction
            _buildDirectionOption(
              title: isSwapped ? 'Original Direction' : 'Swap Direction',
              from: isSwapped
                  ? route.fromCity ?? 'Origin'
                  : route.toCity ?? 'Destination',
              to: isSwapped
                  ? route.toCity ?? 'Destination'
                  : route.fromCity ?? 'Origin',
              isActive: false,
              onTap: () {
                Get.back();
                controller.toggleSwap();
              },
            ),

            const SizedBox(height: 20),

            // Close button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionOption({
    required String title,
    required String from,
    required String to,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.blue.shade300 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive
                          ? Colors.blue.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: isActive
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                from,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isActive
                                      ? Colors.blue.shade900
                                      : Colors.grey.shade800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: isActive
                            ? Colors.blue.shade700
                            : Colors.grey.shade600,
                        size: 16,
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                to,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isActive
                                      ? Colors.blue.shade900
                                      : Colors.grey.shade800,
                                ),
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.flag,
                              size: 14,
                              color: isActive
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isActive)
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
          ],
        ),
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
    if (Get.isRegistered<RouteController>()) {
      Get.delete<RouteController>(force: true);
    }

    if (Get.isRegistered<StationController>()) {
      Get.delete<StationController>(force: true);
    }
    super.dispose();
  }
}
