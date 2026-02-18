import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uscitylink/model/route_model.dart';
import 'package:uscitylink/controller/route_controller.dart';
import 'package:uscitylink/controller/google_map_controller.dart'
    hide GoogleMapController;
import 'package:uscitylink/model/vehicle_gps_model.dart';
import 'station_detail.dart';

class StationMapScreen extends StatefulWidget {
  final RouteModel routeData;

  const StationMapScreen({
    Key? key,
    required this.routeData,
  }) : super(key: key);

  @override
  _StationMapScreenState createState() => _StationMapScreenState();
}

class _StationMapScreenState extends State<StationMapScreen> {
  final RouteController routeController = Get.find<RouteController>();
  final Completer<GoogleMapController> _controller = Completer();
  final Map<MarkerId, Marker> _markers = {};
  bool _isLoading = true;
  Set<Polyline> _polylines = {};

  // Icons - Increased size
  BitmapDescriptor? _stationIcon;
  BitmapDescriptor? _startIcon;
  BitmapDescriptor? _endIcon;
  BitmapDescriptor? _truckIcon;
  BitmapDescriptor? _truckMovingIcon;

  // Camera state
  double _zoomLevel = 10.0;
  LatLng _currentCenter = const LatLng(33.5185892, -86.8103567);

  // Tracking state
  bool _isTrackingTruck = true;
  Timer? _apiTimer;

  // Station data from controller
  List<Stations> get nearbyStations => routeController.nearByStations;
  VehicleGpsModel? get truckLocation => routeController.truckLocation.value;

  @override
  void initState() {
    super.initState();
    _currentCenter = truckLocation != null
        ? LatLng(truckLocation!.latitude, truckLocation!.longitude)
        : LatLng(
            widget.routeData.fromLat as double,
            widget.routeData.fromLng as double,
          );
    _initializeMap();

    // Listen for truck location updates from controller
    _setupTruckLocationListener();

    // Start API timer to refresh data every 10 seconds
    _startApiTimer();
  }

  void _startApiTimer() {
    _apiTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        print('🔄 Refreshing truck location data...');
        // Trigger API call through your controller
        routeController
            .fetchRoutes(); // You'll need to implement this in your controller
      }
    });
  }

  void _setupTruckLocationListener() {
    ever(routeController.truckLocation, (VehicleGpsModel? location) {
      if (location != null && mounted) {
        _updateTruckMarkerFromController(location);
      }
    });
  }

  void _updateTruckMarkerFromController(VehicleGpsModel location) {
    final position = Position(
      latitude: location.latitude,
      longitude: location.longitude,
      timestamp: location.timestamp,
      accuracy: 5.0,
      altitude: 0.0,
      heading: location.headingDegrees ?? 0.0,
      speed: location.speedMilesPerHour ?? 0.0,
      speedAccuracy: 1.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 5.0,
    );

    setState(() {
      // Remove old truck marker
      _markers.remove(const MarkerId('truck'));

      // Add updated truck marker with larger size
      _markers[const MarkerId('truck')] = Marker(
        markerId: const MarkerId('truck'),
        position: LatLng(location.latitude, location.longitude),
        icon: _truckMovingIcon ?? _truckIcon!,
        rotation: location.headingDegrees ?? 0.0,
        anchor: const Offset(0.5, 0.5),
        draggable: false,
        flat: true,
        infoWindow: InfoWindow(
          title: 'Truck ${location.vehicleName}',
          snippet:
              'Speed: ${location.speedMilesPerHour?.toStringAsFixed(1)} mph',
        ),
        onTap: () => _showTruckInfo(position),
      );
    });

    if (_isTrackingTruck) {
      _followTruck(position);
    }
  }

  @override
  void dispose() {
    _apiTimer?.cancel();
    super.dispose();
  }

  Future<void> _followTruck(Position position) async {
    try {
      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: _zoomLevel,
            bearing: position.heading,
          ),
        ),
      );
    } catch (e) {
      print('Error following truck: $e');
    }
  }

  Future<void> _initializeMap() async {
    try {
      await _loadIcons();
      await _createMarkers();
      await _createRoutePolyline();

      setState(() => _isLoading = false);

      Future.delayed(const Duration(milliseconds: 500), () {
        _zoomToFitAllMarkers();
      });
    } catch (e) {
      print('Error initializing map: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _loadIcons() async {
    try {
      print('=== Loading Icons ===');

      // Load truck icons with larger size (increased to 100)
      try {
        final truckIconData = await getBytesFromAsset('assets/truck.png', 100);
        final truckMovingIconData =
            await getBytesFromAsset('assets/truck_moving.png', 100);
        _truckIcon = BitmapDescriptor.bytes(truckIconData);
        _truckMovingIcon = BitmapDescriptor.bytes(truckMovingIconData);
        print('✓ Truck icons loaded');
      } catch (e) {
        print('❌ Could not load truck icon: $e');
        _truckIcon = await _createCustomTruckIcon(
            Icons.local_shipping, Colors.blue, 100);
        _truckMovingIcon = await _createCustomTruckIcon(
            Icons.local_shipping, Colors.green, 100);
      }

      // Load station icon with larger size (increased to 80)
      try {
        final markerIcon =
            await getBytesFromAsset('assets/images/gas_station.png', 80);
        _stationIcon = BitmapDescriptor.bytes(markerIcon);
        print('✓ Station icon loaded');
      } catch (e) {
        print('❌ Could not load station icon: $e');
        _stationIcon = await _createCustomMarker(
          icon: Icons.local_gas_station,
          color: Colors.orange,
          size: 80,
        );
      }

      // Create start/end markers with larger size (increased to 70)
      _startIcon = await _createCustomMarker(
        icon: Icons.flag,
        color: Colors.green,
        size: 70,
      );
      _endIcon = await _createCustomMarker(
        icon: Icons.flag,
        color: Colors.red,
        size: 70,
      );

      print('✓ All icons created successfully');
    } catch (e) {
      print('❌ Error loading icons: $e');
      // Fallback to defaults (default markers have standard size)
      _truckIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      _truckMovingIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      _stationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      _startIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      _endIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<BitmapDescriptor> _createCustomTruckIcon(
      IconData icon, Color color, int size) async {
    return _createCustomMarker(icon: icon, color: color, size: size);
  }

  Future<BitmapDescriptor> _createCustomMarker({
    required IconData icon,
    required Color color,
    int size = 80, // Increased default size
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw shadow (scaled with size)
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(
        Offset(size / 2 + 2, size / 2 + 2),
        size / 2 - 6,
        shadowPaint,
      );

      // Draw main circle (scaled with size)
      final circlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2 - 6,
        circlePaint,
      );

      // Draw white border (scaled with size)
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4; // Increased border width
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2 - 6,
        borderPaint,
      );

      // Draw icon (scaled with size)
      final iconStr = String.fromCharCode(icon.codePoint);
      final textStyle = ui.TextStyle(
        fontSize: size * 0.5,
        fontFamily: icon.fontFamily,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      );

      final paragraphBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(textAlign: TextAlign.center),
      )
        ..pushStyle(textStyle)
        ..addText(iconStr);

      final paragraph = paragraphBuilder.build();
      paragraph.layout(ui.ParagraphConstraints(width: size.toDouble()));

      canvas.drawParagraph(
        paragraph,
        Offset(
          (size - paragraph.width) / 2,
          (size - paragraph.height) / 2,
        ),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      print('Error creating custom marker: $e');
      throw e;
    }
  }

  Future<void> _createMarkers() async {
    try {
      print('=== Creating Markers ===');
      final markers = <MarkerId, Marker>{};

      // Add truck marker from controller (larger size already set in icon)
      if (truckLocation != null) {
        markers[const MarkerId('truck')] = Marker(
          markerId: const MarkerId('truck'),
          position: LatLng(truckLocation!.latitude, truckLocation!.longitude),
          icon: _truckMovingIcon ?? _truckIcon!,
          rotation: truckLocation!.headingDegrees ?? 0.0,
          anchor: const Offset(0.5, 0.5),
          draggable: false,
          flat: true,
          infoWindow: InfoWindow(
            title: 'Truck ${truckLocation!.vehicleName}',
            snippet:
                'Speed: ${truckLocation!.speedMilesPerHour?.toStringAsFixed(1)} mph',
          ),
          onTap: () => _showTruckInfoFromModel(truckLocation!),
        );
        print('✓ Truck marker added');
      }

      // Add station markers from controller's nearbyStations (larger size already set in icon)
      for (var i = 0; i < nearbyStations.length; i++) {
        final station = nearbyStations[i];
        final markerId = MarkerId('station_${station.id}');
        final latLng = LatLng(
          station.latitude as double,
          station.longitude as double,
        );

        markers[markerId] = Marker(
          markerId: markerId,
          position: latLng,
          icon: _stationIcon!,
          infoWindow: InfoWindow(
            title: station.name,
            snippet: station.address,
          ),
          onTap: () => _showStationDetails(station),
          anchor: const Offset(0.5, 0.5),
          draggable: false,
        );
      }

      // Add route start marker (larger size already set in icon)
      markers[const MarkerId('start')] = Marker(
        markerId: const MarkerId('start'),
        position: LatLng(
          widget.routeData.fromLat as double,
          widget.routeData.fromLng as double,
        ),
        icon: _startIcon!,
        infoWindow: InfoWindow(
          title: 'Start: ${widget.routeData.fromCity ?? 'Origin'}',
          snippet: widget.routeData.fromAddress,
        ),
        anchor: const Offset(0.5, 0.5),
        draggable: false,
      );

      // Add route end marker (larger size already set in icon)
      markers[const MarkerId('end')] = Marker(
        markerId: const MarkerId('end'),
        position: LatLng(
          widget.routeData.toLat as double,
          widget.routeData.toLng as double,
        ),
        icon: _endIcon!,
        infoWindow: InfoWindow(
          title: 'End: ${widget.routeData.toCity ?? 'Destination'}',
          snippet: widget.routeData.toAddress,
        ),
        anchor: const Offset(0.5, 0.5),
        draggable: false,
      );

      setState(() {
        _markers.clear();
        _markers.addAll(markers);
      });

      print('=== Markers Created Successfully ===');
      print('Total markers: ${_markers.length}');
      print('Stations: ${nearbyStations.length}');
    } catch (e) {
      print('❌ Error creating markers: $e');
    }
  }

  Future<void> _createRoutePolyline() async {
    try {
      // In a real app, you'd get the full route polyline from Directions API
      // For now, we'll just draw a straight line
      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        width: 4,
        points: [
          LatLng(
            widget.routeData.fromLat as double,
            widget.routeData.fromLng as double,
          ),
          LatLng(
            widget.routeData.toLat as double,
            widget.routeData.toLng as double,
          ),
        ],
      );

      setState(() {
        _polylines = {polyline};
      });

      print('✓ Route polyline created');
    } catch (e) {
      print('Error creating polyline: $e');
    }
  }

  void _showTruckInfoFromModel(VehicleGpsModel truck) {
    final position = Position(
      latitude: truck.latitude,
      longitude: truck.longitude,
      timestamp: truck.timestamp,
      accuracy: 5.0,
      altitude: 0.0,
      heading: truck.headingDegrees ?? 0.0,
      speed: truck.speedMilesPerHour ?? 0.0,
      speedAccuracy: 1.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 5.0,
    );
    _showTruckInfo(position);
  }

  void _showTruckInfo(Position position) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Truck Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Speed', '${position.speed.toStringAsFixed(1)} mph'),
            _buildInfoRow('Heading', '${position.heading.toStringAsFixed(0)}°'),
            _buildInfoRow(
                'Accuracy', '±${position.accuracy.toStringAsFixed(1)} m'),
            _buildInfoRow('Last Update', _formatTime(position.timestamp)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _toggleTruckTracking();
                    },
                    icon:
                        Icon(_isTrackingTruck ? Icons.pause : Icons.play_arrow),
                    label: Text(_isTrackingTruck
                        ? 'Pause Tracking'
                        : 'Resume Tracking'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return '${difference.inHours} hours ago';
    }
  }

  void _toggleTruckTracking() {
    setState(() {
      _isTrackingTruck = !_isTrackingTruck;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(_isTrackingTruck ? 'Tracking enabled' : 'Tracking paused'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _zoomToFitAllMarkers() async {
    try {
      if (_markers.isEmpty) return;

      final controller = await _controller.future;

      // If only one marker, center on it with good zoom
      if (_markers.length == 1) {
        final marker = _markers.values.first;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: marker.position,
              zoom: 14.0, // Good zoom for single point
            ),
          ),
        );
        return;
      }

      // Calculate center point
      double latSum = 0;
      double lngSum = 0;
      final points = _markers.values.map((m) => m.position).toList();

      for (var point in points) {
        latSum += point.latitude;
        lngSum += point.longitude;
      }

      final center = LatLng(
        latSum / points.length,
        lngSum / points.length,
      );

      // Calculate distances to find appropriate zoom
      double maxDistance = 0;
      for (var point in points) {
        final distance = _calculateDistance(center, point);
        if (distance > maxDistance) {
          maxDistance = distance;
        }
      }

      // Convert distance to zoom level
      // Rough formula: zoom = 14 - log2(distance in km)
      double zoomLevel;
      if (maxDistance < 1) {
        // Less than 1km
        zoomLevel = 15.0;
      } else if (maxDistance < 5) {
        // 1-5km
        zoomLevel = 13.0;
      } else if (maxDistance < 10) {
        // 5-10km
        zoomLevel = 12.0;
      } else if (maxDistance < 20) {
        // 10-20km
        zoomLevel = 11.0;
      } else if (maxDistance < 50) {
        // 20-50km
        zoomLevel = 10.0;
      } else if (maxDistance < 100) {
        // 50-100km
        zoomLevel = 9.0;
      } else if (maxDistance < 200) {
        // 100-200km
        zoomLevel = 8.0;
      } else if (maxDistance < 500) {
        // 200-500km
        zoomLevel = 7.0;
      } else {
        zoomLevel = 6.0; // 500km+
      }

      // Ensure minimum zoom level of 10
      zoomLevel = zoomLevel < 10 ? 10 : zoomLevel;

      print('📍 Center: $center');
      print('📍 Max distance: ${maxDistance.toStringAsFixed(2)} km');
      print('📍 Setting zoom level: $zoomLevel');

      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: center,
            zoom: zoomLevel,
          ),
        ),
      );
    } catch (e) {
      print('Error zooming to markers: $e');
    }
  }

// Helper method to calculate distance between two points in kilometers
  double _calculateDistance(LatLng p1, LatLng p2) {
    const double R = 6371; // Earth's radius in km

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

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  void _showStationDetails(Stations station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: StationDetailScreen(station: station),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller.complete(controller);
    print('✓ Google Maps initialized');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentCenter,
            zoom: _zoomLevel,
          ),
          markers: Set<Marker>.of(_markers.values),
          polylines: _polylines,
          myLocationEnabled: false, // Disabled - only show truck and stations
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: true,
          mapType: MapType.normal,
          onMapCreated: _onMapCreated,
          onCameraMove: (position) {
            setState(() {
              _zoomLevel = position.zoom;
              _currentCenter = position.target;
            });
          },
          trafficEnabled: true,
        ),

        // Top App Bar
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.all(12),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live Route Map',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${nearbyStations.length} stations • ${widget.routeData.distance?.toStringAsFixed(1)} miles',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tracking indicator
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _isTrackingTruck
                            ? Colors.green[50]
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.gps_fixed,
                        size: 16,
                        color: _isTrackingTruck ? Colors.green : Colors.grey,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_gas_station,
                              size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            '${nearbyStations.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Zoom Controls
        Positioned(
          right: 16,
          bottom: 180,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildZoomButton(Icons.add, _zoomIn),
                Container(
                  width: 44,
                  height: 36,
                  color: Colors.blue[50],
                  child: Center(
                    child: Text(
                      '${_zoomLevel.toInt()}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                _buildZoomButton(Icons.remove, _zoomOut),
              ],
            ),
          ),
        ),

        // Bottom Action Buttons
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.zoom_out_map,
                  label: 'Show All',
                  color: Colors.blue,
                  onTap: _zoomToFitAllMarkers,
                ),
              ),
              const SizedBox(width: 8),
              _buildCircleButton(
                icon: Icons.local_shipping,
                color: Colors.blue,
                onTap: () {
                  if (truckLocation != null) {
                    final position = Position(
                      latitude: truckLocation!.latitude,
                      longitude: truckLocation!.longitude,
                      timestamp: truckLocation!.timestamp,
                      accuracy: 5.0,
                      altitude: 0.0,
                      heading: truckLocation!.headingDegrees ?? 0.0,
                      speed: truckLocation!.speedMilesPerHour ?? 0.0,
                      speedAccuracy: 1.0,
                      altitudeAccuracy: 0.0,
                      headingAccuracy: 5.0,
                    );
                    _followTruck(position);
                  }
                },
                tooltip: 'Track Truck',
              ),
              const SizedBox(width: 8),
              _buildCircleButton(
                icon: Icons.flag,
                color: Colors.green,
                onTap: _goToStart,
                tooltip: 'Start Point',
              ),
              const SizedBox(width: 8),
              _buildCircleButton(
                icon: Icons.flag,
                color: Colors.red,
                onTap: _goToEnd,
                tooltip: 'End Point',
              ),
              const SizedBox(width: 8),
              _buildCircleButton(
                icon: Icons.directions,
                color: Colors.orange,
                onTap: openMapSmart,
                tooltip: 'Directions',
              ),
            ],
          ),
        ),

        // Live Truck Info Card
        if (truckLocation != null)
          Positioned(
            bottom: 100,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Live: ${truckLocation!.speedMilesPerHour?.toStringAsFixed(0) ?? '0'} mph',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Updates every 10s',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Icon(icon, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              'Loading Map...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation methods
  Future<void> _zoomIn() async {
    try {
      final controller = await _controller.future;
      await controller.animateCamera(CameraUpdate.zoomIn());
    } catch (e) {
      print('Error zooming in: $e');
    }
  }

  Future<void> _zoomOut() async {
    try {
      final controller = await _controller.future;
      await controller.animateCamera(CameraUpdate.zoomOut());
    } catch (e) {
      print('Error zooming out: $e');
    }
  }

  Future<void> _goToStart() async {
    try {
      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              widget.routeData.fromLat as double,
              widget.routeData.fromLng as double,
            ),
            zoom: 14,
          ),
        ),
      );
    } catch (e) {
      print('Error going to start: $e');
    }
  }

  Future<void> _goToEnd() async {
    try {
      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              widget.routeData.toLat as double,
              widget.routeData.toLng as double,
            ),
            zoom: 14,
          ),
        ),
      );
    } catch (e) {
      print('Error going to end: $e');
    }
  }

  Future<void> openMapSmart() async {
    final startLat = widget.routeData.fromLat as double;
    final startLng = widget.routeData.fromLng as double;
    final endLat = widget.routeData.toLat as double;
    final endLng = widget.routeData.toLng as double;

    try {
      final Uri webUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$startLat,$startLng'
        '&destination=$endLat,$endLng'
        '&travelmode=driving',
      );

      if (Platform.isAndroid) {
        final Uri androidUrl = Uri.parse(
          'google.navigation:q=$endLat,$endLng&mode=d',
        );

        if (await canLaunchUrl(androidUrl)) {
          await launchUrl(androidUrl, mode: LaunchMode.externalApplication);
          return;
        }
      }

      if (Platform.isIOS) {
        final Uri iosGoogleMaps = Uri.parse(
          'comgooglemaps://?saddr=$startLat,$startLng&daddr=$endLat,$endLng&directionsmode=driving',
        );

        if (await canLaunchUrl(iosGoogleMaps)) {
          await launchUrl(iosGoogleMaps, mode: LaunchMode.externalApplication);
          return;
        }

        final Uri appleMaps = Uri.parse(
          'https://maps.apple.com/?saddr=$startLat,$startLng&daddr=$endLat,$endLng&dirflg=d',
        );

        if (await canLaunchUrl(appleMaps)) {
          await launchUrl(appleMaps, mode: LaunchMode.externalApplication);
          return;
        }
      }

      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error opening maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
