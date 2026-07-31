import 'package:uscitylink/model/security/security_driver_model.dart';
import 'package:uscitylink/model/security/security_trailer_model.dart';
import 'package:uscitylink/model/security/security_truck_model.dart';

class EntryFormDataModel {
  List<SecurityTruckModel> trucks;
  List<SecurityTrailerModel> trailers;
  List<SecurityDriverModel> drivers;

  EntryFormDataModel({
    this.trucks = const [],
    this.trailers = const [],
    this.drivers = const [],
  });

  EntryFormDataModel.fromJson(Map<String, dynamic> json)
      : trucks = (json['trucks'] as List<dynamic>? ?? [])
            .map((e) => SecurityTruckModel.fromJson(e))
            .toList(),
        trailers = (json['trailers'] as List<dynamic>? ?? [])
            .map((e) => SecurityTrailerModel.fromJson(e))
            .toList(),
        drivers = (json['drivers'] as List<dynamic>? ?? [])
            .map((e) => SecurityDriverModel.fromJson(e))
            .toList();
}
