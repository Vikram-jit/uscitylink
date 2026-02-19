import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/route_controller.dart';
import 'package:uscitylink/model/vehicle_gps_model.dart';

class TruckInfoWidget extends StatefulWidget {
  const TruckInfoWidget({Key? key}) : super(key: key);

  @override
  State<TruckInfoWidget> createState() => _TruckInfoWidgetState();
}

class _TruckInfoWidgetState extends State<TruckInfoWidget> {
  final RouteController routeController = Get.find<RouteController>();
  Timer? _refreshTimer;
  bool _isDisposed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    // Initial fetch after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _fetchTruckData();
      }
    });

    // Set up timer for every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isDisposed && mounted) {
        _fetchTruckData();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _fetchTruckData() async {
    // Prevent multiple simultaneous requests
    if (_isLoading || _isDisposed || !mounted) return;

    _isLoading = true;

    try {
      print('🔄 Auto-refreshing truck data (30s interval)');
      await routeController.fetchRoutes();
    } catch (e) {
      print('Error fetching truck data: $e');
    } finally {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Don't build if disposed
      if (_isDisposed) return const SizedBox.shrink();

      final truck = routeController.truckLocation.value;

      if (truck == null) {
        return _buildNoDataCard();
      }

      return _buildTruckInfoCard(truck);
    });
  }

  Widget _buildTruckInfoCard(VehicleGpsModel truck) {
    // Get fuel color based on percentage
    Color _getFuelColor(int? fuelPercent) {
      if (fuelPercent == null) return Colors.grey;
      if (fuelPercent < 30) return Colors.red;
      if (fuelPercent < 60) return Colors.orange;
      return Colors.green;
    }

    // Get fuel status text
    String _getFuelStatus(int? fuelPercent) {
      if (fuelPercent == null) return 'N/A';
      if (fuelPercent < 30) return 'CRITICAL';
      if (fuelPercent < 60) return 'LOW';
      if (fuelPercent < 80) return 'GOOD';
      return 'FULL';
    }

    // Get fuel icon
    IconData _getFuelIcon(int? fuelPercent) {
      if (fuelPercent == null) return Icons.local_gas_station;
      if (fuelPercent < 30) return Icons.battery_alert;
      if (fuelPercent < 60) return Icons.battery_2_bar;
      if (fuelPercent < 80) return Icons.battery_3_bar;
      return Icons.battery_full;
    }

    // Get speed color
    Color _getSpeedColor(double? speed) {
      if (speed == null) return Colors.grey;
      if (speed > 70) return Colors.red;
      if (speed > 50) return Colors.orange;
      return Colors.green;
    }

    final fuelColor = _getFuelColor(truck.fuelPercent);
    final fuelStatus = _getFuelStatus(truck.fuelPercent);
    final fuelIcon = _getFuelIcon(truck.fuelPercent);
    final speedColor = _getSpeedColor(truck.speedMilesPerHour);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with truck name and refresh indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Truck ${truck.vehicleName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${truck.vehicleId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '30s',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Speed Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: speedColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: speedColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.speed, color: speedColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Speed',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: speedColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getSpeedCategory(truck.speedMilesPerHour ?? 0),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: speedColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${truck.speedMilesPerHour?.toStringAsFixed(1) ?? '0'} mph',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: speedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Fuel Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fuelColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: fuelColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(fuelIcon, color: fuelColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Fuel Level',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: fuelColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  fuelStatus,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: fuelColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${truck.fuelPercent ?? 0}%',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: fuelColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: (truck.fuelPercent ?? 0) / 100,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        fuelColor),
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (truck.fuelPercent != null && truck.fuelPercent! < 30)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.red.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '⚠️ Low fuel! Refuel soon.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Location and Last Update
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        truck.formattedLocation ?? 'Location unknown',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last updated: ${_formatTime(truck.timestamp)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Truck Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Waiting for truck location...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _getSpeedCategory(double speed) {
    if (speed > 70) return 'Overspeeding';
    if (speed > 50) return 'Fast';
    if (speed > 20) return 'Normal';
    return 'Slow';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
