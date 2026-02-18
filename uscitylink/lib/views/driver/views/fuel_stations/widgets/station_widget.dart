import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uscitylink/controller/route_controller.dart';
import 'package:uscitylink/controller/station_controller.dart';
import 'package:uscitylink/model/route_model.dart';
import 'package:uscitylink/views/driver/views/fuel_stations/live_truck_navigation_screen.dart';
import 'package:uscitylink/views/driver/views/fuel_stations/widgets/station_detail.dart';

class StationWidget extends StatelessWidget {
  final RouteController routeController = Get.find<RouteController>();
  final StationController stationController = Get.find<StationController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (routeController.groupedStations.isEmpty) {
        return _buildEmptyState();
      }
      return _buildStationsByState(routeController.groupedStations);
    });
  }

  // Main widget that builds stations grouped by state
  Widget _buildStationsByState(List<StationGroup> groupedStations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with total count
          _buildHeader(groupedStations),
          const SizedBox(height: 16),

          // List of states with their stations
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: groupedStations.length,
            itemBuilder: (context, index) {
              return _buildStateGroupCard(groupedStations[index], context);
            },
          ),
        ],
      ),
    );
  }

  // Header with total stations count
  Widget _buildHeader(List<StationGroup> groupedStations) {
    final totalStations = groupedStations.fold<int>(
      0,
      (sum, group) => sum + group.stationCount,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.local_gas_station,
                color: Colors.orange[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fuel Stations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$totalStations stations available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        // State count indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${groupedStations.length} States',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Card for each state group with expandable stations
  Widget _buildStateGroupCard(StationGroup group, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(Get.context!).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStateColor(group.stateCode),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                group.stateCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  group.stateName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                // padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${group.stationCount} stations',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          children: group.stations.map((station) {
            return _buildStationCard(station, context);
          }).toList(),
        ),
      ),
    );
  }

  // Helper to get state color based on state code
  Color _getStateColor(String stateCode) {
    final colors = {
      'TX': Colors.red,
      'CA': Colors.blue,
      'NY': Colors.purple,
      'FL': Colors.green,
      'IL': Colors.indigo,
      'OH': Colors.deepOrange,
      'AR': Colors.brown,
    };
    return colors[stateCode] ?? Colors.blueGrey;
  }

  // Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_gas_station,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Stations Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stations along your route will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationCard(Stations station, BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StationDetailScreen(station: station),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      station.name ?? "Unnamed Station",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Store #${station.storeNumber}',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${station.address}, ${station.city}, ${station.state} ${station.zipCode}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                station.interstate ?? "Interstate info not available",
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              if (station.fuelPrice != null)
                _buildPriceInfo(station.fuelPrice!),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFacilityIcon(Icons.local_gas_station,
                      'Fuel Lanes: ${station.fuelLaneCount}'),
                  _buildFacilityIcon(Icons.local_parking,
                      'Parking: ${station.parkingSpacesCount}'),
                  _buildFacilityIcon(
                      Icons.shower, 'Showers: ${station.showerCount}'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LiveTruckNavigationScreen(
                              station: station,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.directions, size: 20),
                      label: const Text('Calculate Route'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        launchDirections(
                            context,
                            (station.latitude as double?) ?? 0.0,
                            (station.longitude as double?) ?? 0.0);
                      },
                      icon: const Icon(Icons.directions, size: 20),
                      label: const Text('Get Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StationDetailScreen(station: station),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline),
                    color: Colors.blue[700],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo(FuelPrice price) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        //border: Border.all(color: Colors.green[100]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${price.product} Price',
                style: TextStyle(
                  color: Colors.green[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Effective: ${_formatDate(price.effectiveDate)}',
                style: TextStyle(
                  color: Colors.green[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${price.yourPrice}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
              Text(
                'Save \$${price.savingsTotal}',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[600], size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    late DateTime date;

    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.parse(value);
    } else {
      throw ArgumentError('Invalid date type: ${value.runtimeType}');
    }

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> launchDirections(
    BuildContext context,
    double lat,
    double lng,
  ) async {
    Uri? uri;

    // 1️⃣ Try Google Maps app
    final googleMapsUri = Uri.parse('comgooglemaps://?daddr=$lat,$lng');
    if (await canLaunchUrl(googleMapsUri)) {
      uri = googleMapsUri;
    }

    // 2️⃣ Try Apple Maps app (iOS only)
    else if (Platform.isIOS) {
      final appleMapsUri = Uri.parse('http://maps.apple.com/?daddr=$lat,$lng');
      if (await canLaunchUrl(appleMapsUri)) {
        uri = appleMapsUri;
      }
    }

    // 3️⃣ Fallback to web
    uri ??= Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No maps application available'),
        ),
      );
    }
  }
}
