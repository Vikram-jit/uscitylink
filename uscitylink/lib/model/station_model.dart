class Station {
  final int? id;
  final int? storeNumber;
  final String? name;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? interstate;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final int? parkingSpacesCount;
  final int? fuelLaneCount;
  final int? showerCount;
  final String? amenities;
  final String? restaurants;

  Station({
    this.id,
    this.storeNumber,
    this.name,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.interstate,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.parkingSpacesCount,
    this.fuelLaneCount,
    this.showerCount,
    this.amenities,
    this.restaurants,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'],
      storeNumber: json['store_number'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      interstate: json['interstate'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      phoneNumber: json['phone_number'],
      parkingSpacesCount: json['parking_spaces_count'],
      fuelLaneCount: json['fuel_lane_count'],
      showerCount: json['shower_count'],
      amenities: json['amenities'],
      restaurants: json['restaurants'],
    );
  }
}
