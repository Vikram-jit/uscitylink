class LiveLocationModel {
  String? id;
  String? name;
  String? description;
  String? liveSharingUrl;
  String? formattedAddress;
  double? latitude;
  double? longitude;

  LiveLocationModel({
    this.id,
    this.name,
    this.description,
    this.liveSharingUrl,
    this.formattedAddress,
    this.latitude,
    this.longitude,
  });

  LiveLocationModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    liveSharingUrl = json['liveSharingUrl'];
    formattedAddress = json['formattedAddress'];
    latitude = (json['latitude'] as num?)?.toDouble();
    longitude = (json['longitude'] as num?)?.toDouble();
  }
}
