class SecurityTruckModel {
  int? id;
  String? number;
  String? licensePlateNumber;
  String? latestEntryStatus;

  SecurityTruckModel({
    this.id,
    this.number,
    this.licensePlateNumber,
    this.latestEntryStatus,
  });

  SecurityTruckModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    number = json['number']?.toString();
    licensePlateNumber = json['licensePlateNumber'];
    latestEntryStatus = json['latestEntryStatus'];
  }
}
