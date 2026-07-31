class SecurityEntryListItem {
  int? id;
  String? date;
  String? createdAt;
  String? status; // 'entry' | 'depart'
  String? truckNumber;
  String? truckLicensePlate;
  String? trailerNumber;
  String? trailerLicensePlate;
  String? emptyLoaded;
  String? loadType;
  String? driverNames;
  String? security;

  SecurityEntryListItem({
    this.id,
    this.date,
    this.createdAt,
    this.status,
    this.truckNumber,
    this.truckLicensePlate,
    this.trailerNumber,
    this.trailerLicensePlate,
    this.emptyLoaded,
    this.loadType,
    this.driverNames,
    this.security,
  });

  SecurityEntryListItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    date = json['date'];
    createdAt = json['createdAt'];
    status = json['status'];
    truckNumber = json['truckNumber']?.toString();
    truckLicensePlate = json['truckLicensePlate'];
    trailerNumber = json['trailerNumber']?.toString();
    trailerLicensePlate = json['trailerLicensePlate'];
    emptyLoaded = json['emptyLoaded'];
    loadType = json['loadType'];
    driverNames = json['driverNames'];
    security = json['security'];
  }
}
