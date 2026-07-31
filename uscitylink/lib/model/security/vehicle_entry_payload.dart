/// Request body for POST /security/entries. Field names match the backend's
/// camelCase body keys exactly (see server/src/controllers/securityEntryController.ts).
class VehicleEntryPayload {
  String status; // 'entry' | 'depart'
  int? truckId;
  String? truckFuel;
  String? truckLicensePlate;
  String? security;

  int? trailerId;
  String? trailerFuel;
  String? trailerLicensePlate;
  String? emptyLoaded; // 'empty' | 'loaded'
  String? loadType; // 'refer' | 'dry'

  String? truckKeyAttached; // 'yes' | 'no'
  String? truckMatt;
  String? logBookStand;
  String? securityGuardInspect;
  String? spareTyre;
  String? anualInspection;
  String? registration;
  String? damage;
  String? damageDescription;
  String? fireExt;
  String? warningTriangles;
  String? seal;
  String? alartm;
  String? loadLocks;
  String? setTemp;
  String? runningTemp;

  List<int> driverIds;
  String? description;
  String? logBookRemark;
  String? fuelCard;
  String? fuelCardRemark;

  String? deliveryAddress;
  String? deliveryCity;
  String? deliveryState;
  String? deliveryZipcode;
  String? deliveryCountry;
  double? deliveryLat;
  double? deliveryLng;
  double? deliveryDistanceMiles;
  int? deliveryDurationMinutes;
  String? deliverAt;
  String? departureAt;

  VehicleEntryPayload({
    required this.status,
    this.truckId,
    this.truckFuel,
    this.truckLicensePlate,
    this.security,
    this.trailerId,
    this.trailerFuel,
    this.trailerLicensePlate,
    this.emptyLoaded,
    this.loadType,
    this.truckKeyAttached,
    this.truckMatt,
    this.logBookStand,
    this.securityGuardInspect,
    this.spareTyre,
    this.anualInspection,
    this.registration,
    this.damage,
    this.damageDescription,
    this.fireExt,
    this.warningTriangles,
    this.seal,
    this.alartm,
    this.loadLocks,
    this.setTemp,
    this.runningTemp,
    this.driverIds = const [],
    this.description,
    this.logBookRemark,
    this.fuelCard,
    this.fuelCardRemark,
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryState,
    this.deliveryZipcode,
    this.deliveryCountry,
    this.deliveryLat,
    this.deliveryLng,
    this.deliveryDistanceMiles,
    this.deliveryDurationMinutes,
    this.deliverAt,
    this.departureAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'truckId': truckId,
      'truckFuel': truckFuel,
      'truckLicensePlate': truckLicensePlate,
      'security': security,
      'trailerId': trailerId,
      'trailerFuel': trailerFuel,
      'trailerLicensePlate': trailerLicensePlate,
      'emptyLoaded': emptyLoaded,
      'loadType': loadType,
      'truckKeyAttached': truckKeyAttached,
      'truckMatt': truckMatt,
      'logBookStand': logBookStand,
      'securityGuardInspect': securityGuardInspect,
      'spareTyre': spareTyre,
      'anualInspection': anualInspection,
      'registration': registration,
      'damage': damage,
      'damageDescription': damageDescription,
      'fireExt': fireExt,
      'warningTriangles': warningTriangles,
      'seal': seal,
      'alartm': alartm,
      'loadLocks': loadLocks,
      'setTemp': setTemp,
      'runningTemp': runningTemp,
      'driverIds': driverIds,
      'description': description,
      'logBookRemark': logBookRemark,
      'fuelCard': fuelCard,
      'fuelCardRemark': fuelCardRemark,
      'deliveryAddress': deliveryAddress,
      'deliveryCity': deliveryCity,
      'deliveryState': deliveryState,
      'deliveryZipcode': deliveryZipcode,
      'deliveryCountry': deliveryCountry,
      'deliveryLat': deliveryLat,
      'deliveryLng': deliveryLng,
      'deliveryDistanceMiles': deliveryDistanceMiles,
      'deliveryDurationMinutes': deliveryDurationMinutes,
      'deliverAt': deliverAt,
      'departureAt': departureAt,
    };
  }
}
