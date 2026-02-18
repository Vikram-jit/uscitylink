import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/route_controller.dart';
import 'package:uscitylink/model/route_model.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/driver/views/fuel_stations/widgets/station_map.dart';
import 'package:uscitylink/views/driver/views/fuel_stations/widgets/station_widget.dart';

class FuelStationsView extends StatefulWidget {
  FuelStationsView({
    Key? key,
  }) : super(key: key);

  @override
  State<FuelStationsView> createState() => _FuelStationsViewState();
}

class _FuelStationsViewState extends State<FuelStationsView> {
  RouteController routeController = Get.put(RouteController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Route Information'),
        backgroundColor: TColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(child: Obx(() {
        if (routeController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...routeController.routes.map((route) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRouteHeader(route),
                  const SizedBox(height: 16),
                  _buildMapPreview(route),
                  const SizedBox(height: 16),
                  // _buildTruckSection(route.trucks ?? []),
                  // const SizedBox(height: 16),
                  StationWidget(),
                  // _buildStationsSection(routeController.nearByStations ?? []),
                  const SizedBox(height: 32),
                ],
              );
            }).toList()
          ],
        );
      })),
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
      padding: const EdgeInsets.only(left: 16, right: 16),
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
                  // Map placeholder
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
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.map, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
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
                                Text(
                                  '${routeController.nearByStations.length} stations on map',
                                  style: TextStyle(color: Colors.grey[600]),
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
}
