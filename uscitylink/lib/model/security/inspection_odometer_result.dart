class InspectionOdometerResult {
  double? odometerMiles;

  InspectionOdometerResult({this.odometerMiles});

  InspectionOdometerResult.fromJson(Map<String, dynamic> json)
      : odometerMiles = (json['odometerMiles'] as num?)?.toDouble();
}
