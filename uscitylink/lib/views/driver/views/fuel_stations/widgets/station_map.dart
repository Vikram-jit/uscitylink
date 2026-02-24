import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  bool _isRouteLoading = false;

  Set<Polyline> _polylines = {};

  // API key
  late String _googleApiKey;

  // Icons
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
    _loadApiKey();
    _currentCenter = truckLocation != null
        ? LatLng(truckLocation!.latitude, truckLocation!.longitude)
        : LatLng(
            widget.routeData.fromLat as double,
            widget.routeData.fromLng as double,
          );

    _initializeMap();
    _setupTruckLocationListener();
    _startApiTimer();
  }

  Future<void> _loadApiKey() async {
    await dotenv.load();
    _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (_googleApiKey.isEmpty) {
      print('❌ Google Maps API key not found');
    }
  }

  void _startApiTimer() {
    _apiTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        print('🔄 Refreshing truck location data...');
        routeController.fetchRoutes();
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
    if (!mounted) return;

    setState(() {
      _markers.remove(const MarkerId('truck'));

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
        onTap: () => _showTruckInfoFromModel(location),
      );
    });
  }

  @override
  void dispose() {
    _apiTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      await _loadIcons();
      await _createMarkers();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Load route in background
      _fetchRouteInBackground();
    } catch (e) {
      print('Error initializing map: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchRouteInBackground() async {
    if (!mounted) return;

    setState(() {
      _isRouteLoading = true;
    });

    try {
      await _fetchRoutePolyline();
    } catch (e) {
      print('Error fetching route: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRouteLoading = false;
        });
      }
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

  Future<BitmapDescriptor> _createTruckIcon() async {
    try {
      // Try to load from assets first
      try {
        final Uint8List iconData =
            await getBytesFromAsset('assets/truck.png', 120);
        return BitmapDescriptor.fromBytes(iconData);
      } catch (e) {
        print('Asset truck icon not found, creating custom icon');

        // Create custom truck icon
        final size = 100.0;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        // Draw truck body
        final paint = Paint()
          ..color = Colors.blue.shade700
          ..style = PaintingStyle.fill;

        // Draw rectangle for truck body
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size * 0.2, size * 0.3, size * 0.6, size * 0.4),
            Radius.circular(size * 0.1),
          ),
          paint,
        );

        // Draw cabin
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size * 0.6, size * 0.2, size * 0.25, size * 0.3),
            Radius.circular(size * 0.05),
          ),
          paint,
        );

        // Draw wheels
        final wheelPaint = Paint()..color = Colors.black87;
        canvas.drawCircle(
            Offset(size * 0.3, size * 0.7), size * 0.1, wheelPaint);
        canvas.drawCircle(
            Offset(size * 0.7, size * 0.7), size * 0.1, wheelPaint);

        // Draw window
        final windowPaint = Paint()..color = Colors.white70;
        canvas.drawRect(
          Rect.fromLTWH(size * 0.65, size * 0.25, size * 0.15, size * 0.15),
          windowPaint,
        );

        final picture = recorder.endRecording();
        final image = await picture.toImage(size.toInt(), size.toInt());
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
      }
    } catch (e) {
      print('Error creating truck icon: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  Future<void> _loadIcons() async {
    try {
      print('=== Loading Icons ===');

      // Load truck icons
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
        _truckMovingIcon = await _createTruckIcon();
      }

      // Load station icon
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

      // Create start/end markers
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
    int size = 80,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(
        Offset(size / 2 + 2, size / 2 + 2),
        size / 2 - 6,
        shadowPaint,
      );

      // Draw main circle
      final circlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2 - 6,
        circlePaint,
      );

      // Draw white border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2 - 6,
        borderPaint,
      );

      // Draw icon
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

      // Add truck marker
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
      }

      // Add station markers
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

      // Add start marker
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

      // Add end marker
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

      if (mounted) {
        setState(() {
          _markers.clear();
          _markers.addAll(markers);
        });
      }

      print('=== Markers Created Successfully ===');
      print('Total markers: ${_markers.length}');
    } catch (e) {
      print('❌ Error creating markers: $e');
    }
  }

  // SIMPLIFIED: Just fetch one proper route
// SIMPLIFIED: Just fetch one proper route
  Future<void> _fetchRoutePolyline() async {
    try {
      if (_googleApiKey.isEmpty) {
        await _loadApiKey();
        if (_googleApiKey.isEmpty) return;
      }

      final origin = "${widget.routeData.fromLat},${widget.routeData.fromLng}";
      final destination = "${widget.routeData.toLat},${widget.routeData.toLng}";

      final url = "https://maps.googleapis.com/maps/api/directions/json"
          "?origin=$origin"
          "&destination=$destination"
          "&mode=driving"
          "&key=$_googleApiKey";

      print('📍 Fetching route...');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        _drawSimpleRoute();
        return;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] != 'OK') {
        _drawSimpleRoute();
        return;
      }

      // Get the first route
      final route = data['routes'][0];

      // FIXED: Specify type parameters for compute
      final points = await compute<String, List<LatLng>>(
          _decodePolyline, route['overview_polyline']['points']);

      if (points.isEmpty) {
        _drawSimpleRoute();
        return;
      }

      print('✅ Route fetched with ${points.length} points');

      // Create the polyline
      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        width: 5,
        points: points,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      );

      if (mounted) {
        setState(() {
          _polylines = {polyline};
        });
      }
    } catch (e) {
      print('❌ Error: $e');
      _drawSimpleRoute();
    }
  }

// Background task for polyline decoding
  static List<LatLng> _decodePolyline(String encoded) {
    try {
      final points = PolylinePoints.decodePolyline(encoded);
      return points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    } catch (e) {
      print('Error decoding polyline: $e');
      return [];
    }
  }

  // Simple fallback route
  void _drawSimpleRoute() {
    if (!mounted) return;

    final simpleLine = Polyline(
      polylineId: const PolylineId('route'),
      color: Colors.blue,
      width: 4,
      points: [
        LatLng(widget.routeData.fromLat as double,
            widget.routeData.fromLng as double),
        LatLng(
            widget.routeData.toLat as double, widget.routeData.toLng as double),
      ],
    );

    setState(() {
      _polylines = {simpleLine};
    });
  }

  void _showTruckInfoFromModel(VehicleGpsModel truck) {
    if (!mounted) return;

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
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Truck Location',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Speed', '${position.speed.toStringAsFixed(1)} mph'),
            _buildInfoRow('Heading', '${position.heading.toStringAsFixed(0)}°'),
            _buildInfoRow('Last Update', _formatTime(position.timestamp)),
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
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    return '${difference.inHours}h ago';
  }

  void _showStationDetails(Stations station) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            Expanded(child: StationDetailScreen(station: station)),
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
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapType: MapType.normal,
          onMapCreated: _onMapCreated,
          onCameraMove: (position) {
            if (mounted) {
              setState(() {
                _zoomLevel = position.zoom;
                _currentCenter = position.target;
              });
            }
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

        // Loading indicator for route
        if (_isRouteLoading)
          Positioned(
            top: 100,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Loading route...'),
                ],
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
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Map...'),
          ],
        ),
      ),
    );
  }

  Future<void> _zoomIn() async {
    final controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    final controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.zoomOut());
  }

  Future<void> _zoomToFitAllMarkers() async {
    if (_markers.isEmpty) return;

    try {
      final controller = await _controller.future;
      final bounds = _calculateBounds();
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    } catch (e) {
      print('Error zooming: $e');
    }
  }

  LatLngBounds _calculateBounds() {
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;

    for (var marker in _markers.values) {
      minLat = min(minLat, marker.position.latitude);
      maxLat = max(maxLat, marker.position.latitude);
      minLng = min(minLng, marker.position.longitude);
      maxLng = max(maxLng, marker.position.longitude);
    }

    // Add some padding
    minLat -= 0.05;
    maxLat += 0.05;
    minLng -= 0.05;
    maxLng += 0.05;

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _goToStart() async {
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
  }

  Future<void> _goToEnd() async {
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
  }

  Future<void> openMapSmart() async {
    final startLat = widget.routeData.fromLat as double;
    final startLng = widget.routeData.fromLng as double;
    final endLat = widget.routeData.toLat as double;
    final endLng = widget.routeData.toLng as double;

    try {
      final Uri url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$startLat,$startLng'
        '&destination=$endLat,$endLng'
        '&travelmode=driving',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening maps: $e');
    }
  }
}
