class TruckModel {
  int? id;
  String? samsaraVehicleId;
  String? type;
  String? companyId;
  String? companyUuid;
  String? parkingFees;
  String? trailerPresent;
  String? number;
  int? year;
  String? make;
  String? model;
  String? vin;
  String? licensePlateNumber;
  String? state;
  String? prePassId;
  String? driverFuelId;
  String? fuelCardNumber;
  int? status;
  String? currentPosition;
  String? readyStatus;
  String? assginVehicleEntryId;
  String? assginStatus;
  String? yardType;
  String? yardAddress;
  String? deletedAt;
  String? createdAt;
  String? updatedAt;

  TruckModel({
    this.id,
    this.samsaraVehicleId,
    this.type,
    this.companyId,
    this.companyUuid,
    this.parkingFees,
    this.trailerPresent,
    this.number,
    this.year,
    this.make,
    this.model,
    this.vin,
    this.licensePlateNumber,
    this.state,
    this.prePassId,
    this.driverFuelId,
    this.fuelCardNumber,
    this.status,
    this.currentPosition,
    this.readyStatus,
    this.assginVehicleEntryId,
    this.assginStatus,
    this.yardType,
    this.yardAddress,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  TruckModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    samsaraVehicleId = json['samsara_vehicle_id'];
    type = json['type'];
    companyId = json['company_id'];
    companyUuid = json['company_uuid'];
    parkingFees = json['parking_fees'];
    trailerPresent = json['trailer_present'];
    number = json['number'];
    year = json['year'];
    make = json['make'];
    model = json['model'];
    vin = json['vin'];
    licensePlateNumber = json['license_plate_number'];
    state = json['state'];
    prePassId = json['pre_pass_id'];
    driverFuelId = json['driver_fuel_id'];
    fuelCardNumber = json['fuel_card_number'];
    status = json['status'];
    currentPosition = json['current_position'];
    readyStatus = json['ready_status'];
    assginVehicleEntryId = json['assgin_vehicle_entry_id'];
    assginStatus = json['assgin_status'];
    yardType = json['yard_type'];
    yardAddress = json['yard_address'];
    deletedAt = json['deleted_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['samsara_vehicle_id'] = this.samsaraVehicleId;
    data['type'] = this.type;
    data['company_id'] = this.companyId;
    data['company_uuid'] = this.companyUuid;
    data['parking_fees'] = this.parkingFees;
    data['trailer_present'] = this.trailerPresent;
    data['number'] = this.number;
    data['year'] = this.year;
    data['make'] = this.make;
    data['model'] = this.model;
    data['vin'] = this.vin;
    data['license_plate_number'] = this.licensePlateNumber;
    data['state'] = this.state;
    data['pre_pass_id'] = this.prePassId;
    data['driver_fuel_id'] = this.driverFuelId;
    data['fuel_card_number'] = this.fuelCardNumber;
    data['status'] = this.status;
    data['current_position'] = this.currentPosition;
    data['ready_status'] = this.readyStatus;
    data['assgin_vehicle_entry_id'] = this.assginVehicleEntryId;
    data['assgin_status'] = this.assginStatus;
    data['yard_type'] = this.yardType;
    data['yard_address'] = this.yardAddress;
    data['deleted_at'] = this.deletedAt;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
