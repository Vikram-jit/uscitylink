import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uscitylink/model/route_model.dart';
import 'package:uscitylink/utils/constant/colors.dart';

// Your Stations and FuelPrice models remain the same...

class LiveTruckNavigationScreen extends StatefulWidget {
  final Stations station;

  const LiveTruckNavigationScreen({
    super.key,
    required this.station,
  });

  @override
  State<LiveTruckNavigationScreen> createState() =>
      _LiveTruckNavigationScreenState();
}

class _LiveTruckNavigationScreenState extends State<LiveTruckNavigationScreen> {
  GoogleMapController? _mapController; // Make private with underscore
  Position? currentPosition;
  StreamSubscription<Position>? positionStream;

  // Get API key from environment
  late final String googleApiKey;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  String distance = "";
  String duration = "";

  BitmapDescriptor? truckIcon;
  BitmapDescriptor? stationIcon;

  bool _isLoading = true;
  String? _errorMessage;

  // Zoom level
  double _currentZoom = 14.0;
  bool _showStationDetails = false;

  // Add a flag to track if the widget is disposed
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Cancel all subscriptions
    positionStream?.cancel();
    positionStream = null;

    // Properly dispose the map controller
    _mapController?.dispose();
    _mapController = null;

    super.dispose();
  }

  // Safe method to update map controller
  Future<void> _safeAnimateCamera(CameraUpdate update) async {
    if (_isDisposed || _mapController == null) return;
    try {
      await _mapController!.animateCamera(update);
    } catch (e) {
      print('Error animating camera: $e');
    }
  }

  // Safe method to check if widget is still mounted and not disposed
  bool get _isSafeToUpdate => !_isDisposed && mounted;

  Future<void> _initialize() async {
    try {
      // Load API key from .env file
      await dotenv.load();
      googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

      if (googleApiKey.isEmpty) {
        throw Exception('Google Maps API key not found');
      }

      await loadIcons();
      await _checkPermissionsAndStartTracking();
    } catch (e) {
      if (_isSafeToUpdate) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
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

  Future<void> loadIcons() async {
    try {
      // Load station icon from assets
      try {
        final Uint8List markerIcon =
            await getBytesFromAsset('assets/images/gas_station.png', 500);
        final Uint8List markerTruckIcon =
            await getBytesFromAsset('assets/truck.png', 500);
        stationIcon = BitmapDescriptor.bytes(markerIcon);
        truckIcon = BitmapDescriptor.bytes(markerTruckIcon);
      } catch (e) {
        // Fallback to custom marker
        stationIcon = await _createCustomMarker(
          icon: Icons.local_gas_station,
          color: Colors.orange,
        );
        truckIcon =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      }
    } catch (e) {
      // Fallback to default markers
      stationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  Future<void> _checkPermissionsAndStartTracking() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (_isSafeToUpdate) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them.';
          _isLoading = false;
        });
      }
      return;
    }

    // Check and request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (_isSafeToUpdate) {
          setState(() {
            _errorMessage = 'Location permissions are denied.';
            _isLoading = false;
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (_isSafeToUpdate) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied.';
          _isLoading = false;
        });
      }
      return;
    }

    // Get initial position
    try {
      currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (_isSafeToUpdate) {
        setState(() {
          _isLoading = false;
        });
      }

      await updateMap();

      // Start listening for position updates
      positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (Position position) {
          if (_isDisposed) return;
          currentPosition = position;
          updateMap();
        },
        onError: (error) {
          if (_isSafeToUpdate) {
            setState(() {
              _errorMessage = 'Error getting location updates: $error';
            });
          }
        },
      );
    } catch (e) {
      if (_isSafeToUpdate) {
        setState(() {
          _errorMessage = 'Error getting current position: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> updateMap() async {
    if (_isDisposed || currentPosition == null) return;

    LatLng truck =
        LatLng(currentPosition!.latitude, currentPosition!.longitude);
    LatLng station = LatLng(
      widget.station.latitude ?? 0.0,
      widget.station.longitude ?? 0.0,
    );

    if (_isSafeToUpdate) {
      setState(() {
        markers.clear();

        // Truck marker
        markers.add(Marker(
          markerId: const MarkerId("truck"),
          position: truck,
          icon: truckIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: "Your Truck"),
          rotation: currentPosition!.heading,
          anchor: const Offset(0.5, 0.5),
          onTap: () {
            _showTruckInfo();
          },
        ));

        // Station marker
        markers.add(Marker(
          markerId: const MarkerId("station"),
          position: station,
          icon: stationIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: widget.station.name ?? "Station",
            snippet: _getStationSnippet(),
          ),
          onTap: () {
            _showStationDetailsModal();
          },
        ));
      });
    }

    await getRoute(truck, station);

    // Only animate if not manually zooming and widget is still active
    if (!_showStationDetails && !_isDisposed) {
      await _safeAnimateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: truck,
            zoom: _currentZoom,
            bearing: currentPosition!.heading,
          ),
        ),
      );
    }
  }

  String _getStationSnippet() {
    List<String> details = [];

    if (widget.station.location.isNotEmpty) {
      details.add(widget.station.location);
    }

    if (widget.station.fuelPrice != null) {
      details.add('Price: ${widget.station.fuelPrice!.formattedYourPrice}');
    }

    if (widget.station.parkingSpacesCount != null) {
      details.add('${widget.station.parkingSpacesCount} spots');
    }

    return details.isNotEmpty ? details.join(' • ') : "Tap for details";
  }

  void _showTruckInfo() {
    if (_isDisposed) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Truck'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Speed',
                '${currentPosition?.speed?.toStringAsFixed(1) ?? '0'} m/s'),
            _buildInfoRow('Heading',
                '${currentPosition?.heading?.toStringAsFixed(0) ?? '0'}°'),
            _buildInfoRow('Accuracy',
                '±${currentPosition?.accuracy?.toStringAsFixed(1) ?? '0'} m'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> openMapSmart() async {
    if (_isDisposed) return;

    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waiting for current location...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final startLat = currentPosition!.latitude;
    final startLng = currentPosition!.longitude;
    final endLat = widget.station.latitude ?? 0.0;
    final endLng = widget.station.longitude ?? 0.0;

    try {
      final Uri webUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$startLat,$startLng'
        '&destination=$endLat,$endLng'
        '&travelmode=driving',
      );

      // Android - Try Google Navigation first
      if (Platform.isAndroid) {
        final Uri androidUrl = Uri.parse(
          'google.navigation:q=$endLat,$endLng&mode=d',
        );

        if (await canLaunchUrl(androidUrl)) {
          await launchUrl(androidUrl, mode: LaunchMode.externalApplication);
          return;
        }
      }

      // iOS - Try Google Maps first, then Apple Maps
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

      // Fallback to web version
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (_isSafeToUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps app: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStationDetailsModal() {
    if (_isDisposed) return;

    setState(() {
      _showStationDetails = true;
    });

    // Zoom to station
    _safeAnimateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            widget.station.latitude ?? 0.0,
            widget.station.longitude ?? 0.0,
          ),
          zoom: 18,
        ),
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_gas_station,
                        color: Colors.orange,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.station.name ?? 'Station',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.station.storeNumber != null)
                            Text(
                              'Store #${widget.station.storeNumber}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),

                // Location Section
                _buildDetailSection(
                  title: 'Location',
                  icon: Icons.location_on,
                  children: [
                    _buildDetailRow(
                        Icons.map, 'Address', widget.station.fullAddress),
                    if (widget.station.interstate != null)
                      _buildDetailRow(Icons.traffic, 'Interstate',
                          widget.station.interstate!),
                  ],
                ),

                // Fuel Prices Section
                if (widget.station.fuelPrice != null)
                  _buildDetailSection(
                    title: 'Fuel Prices',
                    icon: Icons.local_gas_station,
                    children: [
                      if (widget.station.fuelPrice!.product != null)
                        _buildDetailRow(Icons.category, 'Product',
                            widget.station.fuelPrice!.product!),
                      _buildDetailRow(Icons.attach_money, 'Your Price',
                          widget.station.fuelPrice!.formattedYourPrice),
                      _buildDetailRow(Icons.trending_up, 'Retail Price',
                          widget.station.fuelPrice!.formattedRetailPrice),
                      _buildDetailRow(Icons.savings, 'Savings',
                          widget.station.fuelPrice!.formattedSavings),
                      if (widget.station.fuelPrice!.effectiveDate != null)
                        _buildDetailRow(
                            Icons.update,
                            'Effective',
                            _formatDate(
                                widget.station.fuelPrice!.effectiveDate!)),
                    ],
                  ),

                // Station Amenities
                _buildDetailSection(
                  title: 'Amenities',
                  icon: Icons.room_service,
                  children: [
                    _buildAmenitiesRow(),
                  ],
                ),

                // Station Facilities
                _buildDetailSection(
                  title: 'Facilities',
                  icon: Icons.business,
                  children: [
                    _buildFacilitiesRow(),
                  ],
                ),

                // Contact Section
                _buildDetailSection(
                  title: 'Contact',
                  icon: Icons.contact_phone,
                  children: [
                    if (widget.station.phoneNumber != null)
                      _buildDetailRow(
                          Icons.phone, 'Phone', widget.station.phoneNumber!),
                  ],
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToStation();
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Navigate Here'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _centerOnStation();
                        },
                        icon: const Icon(Icons.center_focus_strong),
                        label: const Text('Center Map'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Smart Map Navigation Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      openMapSmart();
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Open in Maps App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      if (_isSafeToUpdate) {
        setState(() {
          _showStationDetails = false;
        });
      }
    });
  }

  String _formatDate(String date) {
    try {
      DateTime dateTime = DateTime.parse(date);
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } catch (e) {
      return date;
    }
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...children,
        const Divider(height: 30),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Icon(icon, size: 16, color: Colors.grey[600]),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesRow() {
    List<String> amenitiesList = widget.station.amenities?.split(',') ?? [];
    if (amenitiesList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Text('No amenities listed'),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenitiesList.map((amenity) {
        return Chip(
          label: Text(amenity.trim()),
          backgroundColor: Colors.orange.withOpacity(0.1),
          labelStyle: const TextStyle(color: Colors.orange),
          avatar:
              const Icon(Icons.check_circle, size: 16, color: Colors.orange),
        );
      }).toList(),
    );
  }

  Widget _buildFacilitiesRow() {
    Map<String, int?> facilities = {
      'Parking': widget.station.parkingSpacesCount,
      'Fuel Lanes': widget.station.fuelLaneCount,
      'Showers': widget.station.showerCount,
    };

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.5,
      children: facilities.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.value?.toString() ?? '0',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
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

  void _navigateToStation() {
    if (_isDisposed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting navigation to ${widget.station.name}...'),
        backgroundColor: Colors.blue,
      ),
    );
    // Add your in-app navigation logic here
  }

  void _centerOnStation() {
    _safeAnimateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            widget.station.latitude ?? 0.0,
            widget.station.longitude ?? 0.0,
          ),
          zoom: 16,
        ),
      ),
    );
  }

  Future<void> getRoute(LatLng origin, LatLng dest) async {
    if (_isDisposed) return;

    try {
      String url = "https://maps.googleapis.com/maps/api/directions/json"
          "?origin=${origin.latitude},${origin.longitude}"
          "&destination=${dest.latitude},${dest.longitude}"
          "&mode=driving"
          "&key=$googleApiKey";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to get route: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data["routes"] == null || data["routes"].isEmpty) {
        throw Exception('No routes found');
      }

      final leg = data["routes"][0]["legs"][0];

      if (_isSafeToUpdate) {
        setState(() {
          distance = leg["distance"]["text"];
          duration = leg["duration"]["text"];
        });
      }

      List<PointLatLng> points = PolylinePoints.decodePolyline(
          data["routes"][0]["overview_polyline"]["points"]);

      if (_isSafeToUpdate) {
        setState(() {
          polylines.clear();
          polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.blue,
              width: 6,
              points:
                  points.map((e) => LatLng(e.latitude, e.longitude)).toList(),
            ),
          );
        });
      }
    } catch (e) {
      if (_isSafeToUpdate) {
        setState(() {
          _errorMessage = 'Error getting route: $e';
        });
      }
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(3.0, 20.0);
    });
    _safeAnimateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(3.0, 20.0);
    });
    _safeAnimateCamera(CameraUpdate.zoomOut());
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Truck Navigation")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isLoading = true;
                    });
                    _initialize();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Truck Navigation")),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    LatLng start = currentPosition == null
        ? LatLng(
            widget.station.latitude ?? 0.0,
            widget.station.longitude ?? 0.0,
          )
        : LatLng(currentPosition!.latitude, currentPosition!.longitude);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.station.name ?? "Truck Navigation"),
        backgroundColor: TColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showStationDetailsModal,
            tooltip: 'Station Details',
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: openMapSmart,
            tooltip: 'Open in Maps',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: start, zoom: 14),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: markers,
            polylines: polylines,
            onMapCreated: (c) {
              _mapController = c; // Store the controller properly
            },
            onCameraMove: (position) {
              if (_isSafeToUpdate) {
                setState(() {
                  _currentZoom = position.zoom;
                });
              }
            },
            trafficEnabled: true,
            buildingsEnabled: true,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
            mapType: MapType.normal,
          ),

          // Custom Zoom Controls
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.blue),
                        onPressed: _zoomIn,
                        tooltip: 'Zoom In',
                      ),
                      Container(
                        height: 1,
                        width: 40,
                        color: Colors.grey[300],
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.blue),
                        onPressed: _zoomOut,
                        tooltip: 'Zoom Out',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${_currentZoom.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Station Quick Info Card
          if (!_showStationDetails)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: _showStationDetailsModal,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_gas_station,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.station.name ?? 'Station',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getStationSnippet(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Distance/ETA Card
          if (distance.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoColumn(
                        label: "Distance",
                        value: distance,
                        icon: Icons.place,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      _buildInfoColumn(
                        label: "ETA",
                        value: duration,
                        icon: Icons.access_time,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnStation,
        mini: true,
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  Widget _buildInfoColumn({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
