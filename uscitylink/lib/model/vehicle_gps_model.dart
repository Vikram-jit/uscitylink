class VehicleGpsModel {
  final String vehicleId;
  final String vehicleName;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double? headingDegrees;
  final double? speedMilesPerHour;
  final String? formattedLocation;

  VehicleGpsModel({
    required this.vehicleId,
    required this.vehicleName,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.headingDegrees,
    this.speedMilesPerHour,
    this.formattedLocation,
  });

  // Factory constructor to create an object from the API JSON
  factory VehicleGpsModel.fromJson(Map<String, dynamic> json) {
    final vehicle = json;
    final gps = vehicle['gps'] ?? {};

    return VehicleGpsModel(
      vehicleId: vehicle['id'] ?? '',
      vehicleName: vehicle['name'] ?? 'Unknown',
      timestamp:
          DateTime.parse(gps['time'] ?? DateTime.now().toIso8601String()),
      latitude: (gps['latitude'] ?? 0.0).toDouble(),
      longitude: (gps['longitude'] ?? 0.0).toDouble(),
      headingDegrees: (gps['headingDegrees']?.toDouble()),
      speedMilesPerHour: (gps['speedMilesPerHour']?.toDouble()),
      formattedLocation: gps['reverseGeo']?['formattedLocation'],
    );
  }
}
