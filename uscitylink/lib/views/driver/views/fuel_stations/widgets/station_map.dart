import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uscitylink/model/route_model.dart';
import 'station_detail.dart';

class StationMapScreen extends StatefulWidget {
  final List<Station> stations;
  final RouteModel routeData;

  const StationMapScreen({
    Key? key,
    required this.stations,
    required this.routeData,
  }) : super(key: key);

  @override
  _StationMapScreenState createState() => _StationMapScreenState();
}

class _StationMapScreenState extends State<StationMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Map<MarkerId, Marker> _markers = {};
  bool _isLoading = true;
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _stationIcon;
  BitmapDescriptor? _startIcon;
  BitmapDescriptor? _endIcon;

  // Camera state
  double _zoomLevel = 10.0;
  LatLng _currentCenter = const LatLng(33.5185892, -86.8103567);

  @override
  void initState() {
    super.initState();
    _currentCenter = LatLng(
      widget.routeData.fromDetails.lat,
      widget.routeData.fromDetails.lng,
    );
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Load icons FIRST
      await _loadIcons();

      // Then create markers and polyline
      await _createMarkers();
      await _createRoutePolyline();

      setState(() => _isLoading = false);

      // Auto-zoom after a short delay
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

      // Load station icon from assets
      try {
        final Uint8List markerIcon =
            await getBytesFromAsset('assets/images/gas_station.png', 500);

        _stationIcon = BitmapDescriptor.bytes(markerIcon);
        print('✓ Station icon loaded from assets');
      } catch (e) {
        print('❌ Could not load station icon: $e');
        // Fallback to custom marker
        _stationIcon = await _createCustomMarker(
          icon: Icons.local_gas_station,
          color: Colors.orange,
        );
        print('✓ Created custom station icon');
      }

      // Create start and end markers programmatically
      _startIcon = await _createCustomMarker(
        icon: Icons.flag,
        color: Colors.green,
      );

      _endIcon = await _createCustomMarker(
        icon: Icons.flag,
        color: Colors.red,
      );

      print('✓ Start and end icons created');
    } catch (e) {
      print('❌ Error loading icons: $e');
      // Fallback to default markers
      _stationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      _startIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      _endIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<BitmapDescriptor> _createCustomMarker({
    required IconData icon,
    required Color color,
    int size = 64,
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
        ..strokeWidth = 3;
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
        ui.ParagraphStyle(
          textAlign: TextAlign.center,
        ),
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
      print('Number of stations: ${widget.stations.length}');

      final markers = <MarkerId, Marker>{};

      // Create station markers with loaded icon
      for (var i = 0; i < widget.stations.length; i++) {
        final station = widget.stations[i];
        final markerId = MarkerId('station_${station.id}');
        final latLng = LatLng(station.latitude, station.longitude);

        print('Station ${i + 1}: ${station.name}');
        print('  Location: ${station.latitude}, ${station.longitude}');

        markers[markerId] = Marker(
          markerId: markerId,
          position: latLng,
          icon: _stationIcon!,
          // Use loaded asset icon
          infoWindow: InfoWindow(
            title: station.name,
            snippet: station.address,
          ),
          onTap: () => _showStationDetails(station),
          anchor: const Offset(0.5, 0.5), // Center the icon
        );
      }

      // Add route start marker
      final startLatLng = LatLng(
        widget.routeData.fromDetails.lat,
        widget.routeData.fromDetails.lng,
      );

      print('Start Point: ${widget.routeData.fromDetails.city}');
      print('  Location: ${startLatLng.latitude}, ${startLatLng.longitude}');

      markers[const MarkerId('start')] = Marker(
        markerId: const MarkerId('start'),
        position: startLatLng,
        icon: _startIcon!, // Use custom start icon
        infoWindow: InfoWindow(
          title: 'Start: ${widget.routeData.fromDetails.city}',
          snippet: widget.routeData.fromDetails.address,
        ),
        anchor: const Offset(0.5, 0.5),
      );

      // Add route end marker
      final endLatLng = LatLng(
        widget.routeData.toDetails.lat,
        widget.routeData.toDetails.lng,
      );

      print('End Point: ${widget.routeData.toDetails.city ?? 'Destination'}');
      print('  Location: ${endLatLng.latitude}, ${endLatLng.longitude}');

      markers[const MarkerId('end')] = Marker(
        markerId: const MarkerId('end'),
        position: endLatLng,
        icon: _endIcon!, // Use custom end icon
        infoWindow: InfoWindow(
          title:
              'End: ${widget.routeData.toDetails.city ?? widget.routeData.toDetails.address.split(',')[0]}',
          snippet: widget.routeData.toDetails.address,
        ),
        anchor: const Offset(0.5, 0.5),
      );

      setState(() {
        _markers.clear();
        _markers.addAll(markers);
      });

      print('=== Markers Created Successfully ===');
      print('Total markers: ${_markers.length}');
    } catch (e) {
      print('❌ Error creating markers: $e');
      print('Stack trace: ${e.toString()}');
    }
  }

  Future<void> _createRoutePolyline() async {
    try {
      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        width: 3,
        points: [
          LatLng(widget.routeData.fromDetails.lat,
              widget.routeData.fromDetails.lng),
          LatLng(
              widget.routeData.toDetails.lat, widget.routeData.toDetails.lng),
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

  Future<void> _zoomToFitAllMarkers() async {
    try {
      if (_markers.isEmpty) return;

      final List<LatLng> points = [];

      // Add all marker positions
      for (final marker in _markers.values) {
        points.add(marker.position);
      }

      if (points.length < 2) {
        // If only one point, zoom to it
        final controller = await _controller.future;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: points.first,
              zoom: 14,
            ),
          ),
        );
        return;
      }

      // Calculate bounds
      double minLat = points[0].latitude;
      double maxLat = points[0].latitude;
      double minLng = points[0].longitude;
      double maxLng = points[0].longitude;

      for (final point in points) {
        minLat = point.latitude < minLat ? point.latitude : minLat;
        maxLat = point.latitude > maxLat ? point.latitude : maxLat;
        minLng = point.longitude < minLng ? point.longitude : minLng;
        maxLng = point.longitude > maxLng ? point.longitude : maxLng;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat - 0.05, minLng - 0.05),
        northeast: LatLng(maxLat + 0.05, maxLng + 0.05),
      );

      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );

      print('✓ Zoomed to fit all markers');
    } catch (e) {
      print('Error zooming to markers: $e');
    }
  }

  void _showStationDetails(Station station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
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
        );
      },
    );
  }

  // ... Rest of the methods (zoomIn, zoomOut, goToStart, goToEnd, etc.) remain the same ...

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller.complete(controller);
    print('✓ Google Maps initialized');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Stack(
      children: [
        // Google Map
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentCenter,
            zoom: _zoomLevel,
          ),
          markers: Set<Marker>.of(_markers.values),
          polylines: _polylines,
          myLocationEnabled: true,
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
                            'Route Map',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.stations.length} stations • ${widget.routeData.distance.toStringAsFixed(1)} miles',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                            '${widget.stations.length}',
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
                Material(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _zoomIn,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.add, color: Colors.blue),
                    ),
                  ),
                ),
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
                Material(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _zoomOut,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.remove, color: Colors.blue),
                    ),
                  ),
                ),
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
                icon: Icons.flag,
                color: Colors.green,
                onTap: _goToStart,
                tooltip: 'Start',
              ),
              const SizedBox(width: 8),
              _buildCircleButton(
                icon: Icons.flag,
                color: Colors.red,
                onTap: _goToEnd,
                tooltip: 'End',
              ),
              const SizedBox(width: 8),
              _buildCircleButton(
                icon: Icons.directions,
                color: Colors.blue,
                onTap: openMapSmart,
                tooltip: 'Directions',
              ),
            ],
          ),
        ),

        // Debug Info Box
        Positioned(
          left: 16,
          top: MediaQuery.of(context).padding.top + 80,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Map Info',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Markers: ${_markers.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                Text(
                  'Zoom: ${_zoomLevel.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                if (_stationIcon != null)
                  const Text(
                    '✓ Custom icons loaded',
                    style: TextStyle(color: Colors.green, fontSize: 10),
                  ),
              ],
            ),
          ),
        ),
      ],
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

  // Add the missing methods that were referenced
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
              widget.routeData.fromDetails.lat,
              widget.routeData.fromDetails.lng,
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
              widget.routeData.toDetails.lat,
              widget.routeData.toDetails.lng,
            ),
            zoom: 14,
          ),
        ),
      );
    } catch (e) {
      print('Error going to end: $e');
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      final controller = await _controller.future;
      final midLat =
          (widget.routeData.fromDetails.lat + widget.routeData.toDetails.lat) /
              2;
      final midLng =
          (widget.routeData.fromDetails.lng + widget.routeData.toDetails.lng) /
              2;

      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(midLat, midLng),
            zoom: _zoomLevel,
          ),
        ),
      );
    } catch (e) {
      print('Error going to location: $e');
    }
  }

  Future<void> openMapSmart() async {
    final startLat = widget.routeData.fromDetails.lat;
    final startLng = widget.routeData.fromDetails.lng;
    final endLat = widget.routeData.toDetails.lat;
    final endLng = widget.routeData.toDetails.lng;

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
