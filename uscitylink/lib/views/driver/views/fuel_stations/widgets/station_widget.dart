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
    return Container(
      color: Colors.grey[50],
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: groupedStations.length,
            itemBuilder: (context, index) {
              return _buildStateGroupCard(groupedStations[index], context);
            },
          ),
          const SizedBox(height: 20),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.shade400,
                      Colors.orange.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_gas_station_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fuel Stations',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalStations stations available across ${groupedStations.length} states',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card for each state group with expandable stations
  Widget _buildStateGroupCard(StationGroup group, BuildContext context) {
    // Count recommended stations in this state
    final recommendedCount =
        group.stations.where((s) => s.isRecommended == true).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: ExpansionTileThemeData(
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            iconColor: Colors.orange.shade600,
            collapsedIconColor: Colors.grey.shade600,
            textColor: Colors.black87,
            collapsedTextColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getStateColor(group.stateCode),
                  _getStateColor(group.stateCode).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _getStateColor(group.stateCode).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                group.stateCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.stateName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (recommendedCount > 0)
                      Text(
                        '$recommendedCount stations near your route',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              '${group.stationCount}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ),
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: group.stations.map((station) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildStationCard(station, context),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationCard(Stations station, BuildContext context) {
    final isRecommended = station.isRecommended == true;
    final isCheapestInState = station.isCheapestInState == true;
    final isNearestStation = station.isNearestStation == true;
    final isBoth = station.isBothNearestAndCheapest == true;

    final currentPrice = station.fuelPrice?.yourPrice != null
        ? double.tryParse(station.fuelPrice!.yourPrice!)
        : null;

    final retailPrice = station.fuelPrice?.retailPrice != null
        ? double.tryParse(station.fuelPrice!.retailPrice!)
        : null;

    final savings = (currentPrice != null && retailPrice != null)
        ? retailPrice - currentPrice
        : null;

    // Determine card styling based on priority
    Color cardColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Color badgeColor = Colors.grey.shade100;
    Color badgeTextColor = Colors.grey.shade800;
    String badgeIcon = '';
    String badgeText = '';

    if (isBoth) {
      cardColor = Colors.amber.shade50;
      borderColor = Colors.amber.shade400;
      badgeColor = Colors.red.shade100;
      badgeTextColor = Colors.red.shade800;
      badgeIcon = '⭐';
      badgeText = 'NEAREST & RECOMMENED';
    } else if (isNearestStation) {
      cardColor = Colors.red.shade50;
      borderColor = Colors.red.shade400;
      badgeColor = Colors.red.shade100;
      badgeTextColor = Colors.red.shade800;
      badgeIcon = '🚨';
      badgeText = 'NEAREST STATION';
    } else if (isCheapestInState) {
      cardColor = Colors.green.shade50;
      borderColor = Colors.green.shade400;
      badgeColor = Colors.green.shade100;
      badgeTextColor = Colors.green.shade800;
      badgeIcon = '🏆';
      badgeText = 'BEST PRICE';
    }

    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isBoth || isNearestStation || isCheapestInState
                ? borderColor
                : Colors.grey.shade200,
            width:
                isBoth ? 2.5 : (isNearestStation || isCheapestInState ? 2 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: isBoth || isNearestStation || isCheapestInState
                  ? borderColor.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: isBoth || isNearestStation || isCheapestInState
                ? cardColor
                : Colors.white,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StationDetailScreen(station: station),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with badges
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Station Logo/Initial
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isBoth
                                ? Colors.amber.shade100
                                : (isNearestStation
                                    ? Colors.red.shade100
                                    : (isCheapestInState
                                        ? Colors.green.shade100
                                        : Colors.orange.shade50)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isBoth
                                  ? Colors.amber.shade300
                                  : (isNearestStation
                                      ? Colors.red.shade300
                                      : (isCheapestInState
                                          ? Colors.green.shade300
                                          : Colors.orange.shade200)),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              station.name?.substring(0, 1).toUpperCase() ??
                                  'S',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isBoth
                                    ? Colors.amber.shade700
                                    : (isNearestStation
                                        ? Colors.red.shade700
                                        : (isCheapestInState
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Station Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                station.name ?? "Unnamed Station",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: (isBoth ||
                                          isNearestStation ||
                                          isCheapestInState)
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isBoth
                                      ? Colors.amber.shade800
                                      : (isNearestStation
                                          ? Colors.red.shade800
                                          : (isCheapestInState
                                              ? Colors.green.shade800
                                              : Colors.black87)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Store #${station.storeNumber}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              // Show "Near Route" badge for recommended stations
                              if (isRecommended)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star,
                                            size: 10,
                                            color: Colors.amber.shade800),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Near Route',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.amber.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Price Badge
                        if (currentPrice != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isCheapestInState
                                  ? Colors.green.shade100
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCheapestInState
                                    ? Colors.green.shade300
                                    : Colors.blue.shade200,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '\$${currentPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCheapestInState
                                        ? Colors.green.shade700
                                        : Colors.blue.shade700,
                                  ),
                                ),
                                if (station.fuelPrice?.product != null)
                                  Text(
                                    station.fuelPrice!.product!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isCheapestInState
                                          ? Colors.green.shade600
                                          : Colors.blue.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Address and Interstate
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${station.address}, ${station.city}, ${station.state} ${station.zipCode}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                          if (station.interstate != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.traffic_outlined,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  station.interstate!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Distance from route - ONLY SHOW FOR RECOMMENDED STATIONS
                    if (isRecommended && station.distanceFromRoute != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: station.distanceFromRoute! < 10
                              ? Colors.green.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.route,
                              size: 16,
                              color: station.distanceFromRoute! < 10
                                  ? Colors.green.shade600
                                  : Colors.blue.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${station.distanceFromRoute!.toStringAsFixed(1)} miles from your route',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: station.distanceFromRoute! < 10
                                      ? Colors.green.shade700
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Distance from truck - SHOW FOR ALL STATIONS
                    if (station.distanceFromTruck != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: station.distanceFromTruck! < 50
                              ? Colors.blue.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_shipping,
                              size: 16,
                              color: station.distanceFromTruck! < 50
                                  ? Colors.blue.shade600
                                  : Colors.orange.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${station.distanceFromTruck!.toStringAsFixed(1)} miles from your truck',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: station.distanceFromTruck! < 50
                                      ? Colors.blue.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Status Badge (for nearest/cheapest/both)
                    if (isBoth || isNearestStation || isCheapestInState) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              badgeIcon,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                color: badgeTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isBoth) ...[
                              const SizedBox(width: 4),
                              Text(
                                '• ${station.distanceFromTruck!.toStringAsFixed(1)} miles',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: badgeTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Fuel Price Details
                    if (station.fuelPrice != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCheapestInState
                              ? Colors.green.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCheapestInState
                                ? Colors.green.shade200
                                : Colors.blue.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Your Price',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (savings != null && savings > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Save \$${savings.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Retail Price',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                Text(
                                  '\$${station.fuelPrice!.retailPrice}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Facilities Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFacilityChip(
                          Icons.local_gas_station_rounded,
                          '${station.fuelLaneCount ?? 0} Lanes',
                          isRecommended ? Colors.green : Colors.blue,
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                        _buildFacilityChip(
                          Icons.local_parking_rounded,
                          '${station.parkingSpacesCount ?? 0} Spots',
                          isRecommended ? Colors.green : Colors.blue,
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                        _buildFacilityChip(
                          Icons.shower_rounded,
                          '${station.showerCount ?? 0} Showers',
                          isRecommended ? Colors.green : Colors.blue,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LiveTruckNavigationScreen(
                                    station: station,
                                    truckLat: routeController
                                            .truckLocation.value?.latitude ??
                                        00,
                                    truckLng: routeController
                                            .truckLocation.value?.longitude ??
                                        00,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCheapestInState
                                  ? Colors.green.shade600
                                  : (isNearestStation
                                      ? Colors.red.shade600
                                      : Colors.blue.shade600),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('Route'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              launchDirections(
                                context,
                                (station.latitude as double?) ?? 0.0,
                                (station.longitude as double?) ?? 0.0,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isCheapestInState
                                  ? Colors.green.shade700
                                  : (isNearestStation
                                      ? Colors.red.shade700
                                      : Colors.blue.shade700),
                              side: BorderSide(
                                color: isCheapestInState
                                    ? Colors.green.shade300
                                    : (isNearestStation
                                        ? Colors.red.shade300
                                        : Colors.blue.shade300),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Navigate'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      StationDetailScreen(station: station),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.info_outline_rounded,
                              color: isCheapestInState
                                  ? Colors.green.shade700
                                  : (isNearestStation
                                      ? Colors.red.shade700
                                      : Colors.blue.shade700),
                              size: 20,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Best Price Badge (Bottom) - Only show if cheapest in state
                    if (isCheapestInState && !isBoth) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.attach_money,
                                    size: 12, color: Colors.green.shade800),
                                const SizedBox(width: 4),
                                Text(
                                  'Best Price in ${station.state}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Nearest Station Badge (Bottom) - Only show if nearest
                    if (isNearestStation && !isBoth) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '🚨',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Closest to you',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}

Widget _buildFacilityChip(IconData icon, String label, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

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

Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.local_gas_station_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'No Stations Available',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Stations along your route will appear here',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    ),
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

  final googleMapsUri = Uri.parse('comgooglemaps://?daddr=$lat,$lng');
  if (await canLaunchUrl(googleMapsUri)) {
    uri = googleMapsUri;
  } else if (Platform.isIOS) {
    final appleMapsUri = Uri.parse('http://maps.apple.com/?daddr=$lat,$lng');
    if (await canLaunchUrl(appleMapsUri)) {
      uri = appleMapsUri;
    }
  }

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
