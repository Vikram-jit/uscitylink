// MySQL DECIMAL columns (lat/lng/distance_miles) come back from Sequelize as
// strings, not numbers, so parsing needs to accept either.
double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

class SecurityEntryDelivery {
  String? deliverAt;
  String? departureAt;
  String? address;
  String? city;
  String? state;
  String? zipcode;
  String? country;
  double? lat;
  double? lng;
  double? distanceMiles;
  int? durationMinutes;

  SecurityEntryDelivery.fromJson(Map<String, dynamic> json) {
    deliverAt = json['deliverAt'];
    departureAt = json['departureAt'];
    address = json['address'];
    city = json['city'];
    state = json['state'];
    zipcode = json['zipcode'];
    country = json['country'];
    lat = _toDouble(json['lat']);
    lng = _toDouble(json['lng']);
    distanceMiles = _toDouble(json['distanceMiles']);
    durationMinutes = json['durationMinutes'];
  }
}

/// Full read-only record for the entry detail screen — field set mirrors
/// VehicleEntryPayload (the create-form submit body) exactly, since it's
/// the same daily_vehicle_entries row, just fetched instead of submitted.
class SecurityEntryDetail {
  int? id;
  String? date;
  String? createdAt;
  String? updatedAt;
  String? status;

  int? truckId;
  String? truckFuel;
  String? truckLicensePlate;
  String? truckNumber;

  int? trailerId;
  String? trailerFuel;
  String? trailerLicensePlate;
  String? trailerNumber;

  String? driverNames;
  String? emptyLoaded;
  String? loadType;

  String? truckKeyAttached;
  String? truckMatt;
  String? logBookStand;
  String? securityGuardInspect;
  String? spareTyre;
  // Kept for viewing older entries only — no longer collected on new
  // submissions (replaced by paperWork).
  String? anualInspection;
  String? registration;
  String? paperWork;
  String? damage;
  String? damageDescription;
  String? fireExt;
  String? warningTriangles;
  String? seal;
  String? alartm;
  String? loadLocks;
  String? setTemp;
  String? runningTemp;

  String? logBookRemark;
  String? fuelCard;
  String? fuelCardRemark;
  String? description;
  String? security;

  SecurityEntryDelivery? delivery;

  SecurityEntryDetail.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    date = json['date'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    status = json['status'];

    truckId = json['truckId'];
    truckFuel = json['truckFuel'];
    truckLicensePlate = json['truckLicensePlate'];
    truckNumber = json['truckNumber']?.toString();

    trailerId = json['trailerId'];
    trailerFuel = json['trailerFuel'];
    trailerLicensePlate = json['trailerLicensePlate'];
    trailerNumber = json['trailerNumber']?.toString();

    driverNames = json['driverNames'];
    emptyLoaded = json['emptyLoaded'];
    loadType = json['loadType'];

    truckKeyAttached = json['truckKeyAttached'];
    truckMatt = json['truckMatt'];
    logBookStand = json['logBookStand'];
    securityGuardInspect = json['securityGuardInspect'];
    spareTyre = json['spareTyre'];
    anualInspection = json['anualInspection'];
    registration = json['registration'];
    paperWork = json['paperWork'];
    damage = json['damage'];
    damageDescription = json['damageDescription'];
    fireExt = json['fireExt'];
    warningTriangles = json['warningTriangles'];
    seal = json['seal'];
    alartm = json['alartm'];
    loadLocks = json['loadLocks'];
    setTemp = json['setTemp'];
    runningTemp = json['runningTemp'];

    logBookRemark = json['logBookRemark'];
    fuelCard = json['fuelCard'];
    fuelCardRemark = json['fuelCardRemark'];
    description = json['description'];
    security = json['security'];

    delivery = json['delivery'] != null
        ? SecurityEntryDelivery.fromJson(json['delivery'])
        : null;
  }

  bool get hasTrailer => trailerId != null;
  bool get isLoaded => emptyLoaded == 'loaded';
}
