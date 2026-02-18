import 'package:uscitylink/model/vehicle_model.dart';

class RouteModel {
  int? id;
  String? fromLocation;
  String? toLocation;
  int? distance;
  String? createdAt;
  String? updatedAt;
  String? fromAddress;
  String? fromCity;
  String? fromState;
  String? fromZip;
  String? fromCountry;
  double? fromLat;
  double? fromLng;
  String? toAddress;
  String? toCity;
  String? toState;
  String? toZip;
  String? toCountry;
  double? toLat;
  double? toLng;
  VehicleModel? truck;
  List<Trucks>? trucks;
  List<Stations>? stations;

  RouteModel(
      {this.id,
      this.fromLocation,
      this.toLocation,
      this.distance,
      this.createdAt,
      this.updatedAt,
      this.fromAddress,
      this.fromCity,
      this.fromState,
      this.fromZip,
      this.fromCountry,
      this.fromLat,
      this.fromLng,
      this.toAddress,
      this.toCity,
      this.toState,
      this.toZip,
      this.toCountry,
      this.toLat,
      this.toLng,
      this.trucks,
      this.stations});

  RouteModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fromLocation = json['from_location'];
    toLocation = json['to_location'];
    distance = json['distance'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    fromAddress = json['from_address'];
    fromCity = json['from_city'];
    fromState = json['from_state'];
    fromZip = json['from_zip'];
    fromCountry = json['from_country'];
    fromLat = double.tryParse(json['from_lat'] ?? "0.0");
    fromLng = double.tryParse(json['from_lng'] ?? "0.0");
    toAddress = json['to_address'];
    toCity = json['to_city'];
    toState = json['to_state'];
    toZip = json['to_zip'];
    toCountry = json['to_country'];
    toLat = double.tryParse(json['to_lat'] ?? "0.0");
    toLng = double.tryParse(json['to_lng'] ?? "0.0");
    if (json['trucks'] != null) {
      trucks = <Trucks>[];
      json['trucks'].forEach((v) {
        trucks!.add(new Trucks.fromJson(v));
      });
    }
    if (json["truck"] != null) {
      truck = VehicleModel.fromJson(json["truck"]);
    }
    if (json['stations'] != null) {
      stations = <Stations>[];
      json['stations'].forEach((v) {
        stations!.add(new Stations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['from_location'] = this.fromLocation;
    data['to_location'] = this.toLocation;
    data['distance'] = this.distance;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['from_address'] = this.fromAddress;
    data['from_city'] = this.fromCity;
    data['from_state'] = this.fromState;
    data['from_zip'] = this.fromZip;
    data['from_country'] = this.fromCountry;
    data['from_lat'] =
        double.tryParse(this.fromLat?.toString() ?? "0.0") ?? 0.0;
    data['from_lng'] =
        double.tryParse(this.fromLng?.toString() ?? "0.0") ?? 0.0;
    data['to_address'] = this.toAddress;
    data['to_city'] = this.toCity;
    data['to_state'] = this.toState;
    data['to_zip'] = this.toZip;
    data['to_country'] = this.toCountry;
    data['to_lat'] = double.tryParse(this.toLat?.toString() ?? "0.0") ?? 0.0;
    data['to_lng'] = double.tryParse(this.toLng?.toString() ?? "0.0") ?? 0.0;
    if (this.trucks != null) {
      data['trucks'] = this.trucks!.map((v) => v.toJson()).toList();
    }
    if (this.truck != null) {
      data['truck'] = this.truck;
    }
    if (this.stations != null) {
      data['stations'] = this.stations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Trucks {
  int? id;
  String? number;

  Trucks({this.id, this.number});

  Trucks.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    number = json['number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['number'] = this.number;
    return data;
  }
}

class Stations {
  int? id;
  int? storeNumber;
  String? name;
  String? address;
  String? city;
  String? state;
  String? zipCode;
  String? interstate;
  double? latitude;
  double? longitude;
  String? phoneNumber;
  int? parkingSpacesCount;
  int? fuelLaneCount;
  int? showerCount;
  String? amenities;
  String? restaurants;
  FuelPrice? fuelPrice;

  Stations({
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
    this.fuelPrice,
  });

  Stations.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    storeNumber = json['store_number'];
    name = json['name'];
    address = json['address'];
    city = json['city'];
    state = json['state'];
    zipCode = json['zip_code'];
    interstate = json['interstate'];
    latitude = double.tryParse(json['latitude']?.toString() ?? "0.0");
    longitude = double.tryParse(json['longitude']?.toString() ?? "0.0");
    phoneNumber = json['phone_number'];
    parkingSpacesCount = json['parking_spaces_count'];
    fuelLaneCount = json['fuel_lane_count'];
    showerCount = json['shower_count'];
    amenities = json['amenities'];
    restaurants = json['restaurants'];
    fuelPrice = json['latest_price'] != null
        ? FuelPrice.fromJson(json['latest_price'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['store_number'] = storeNumber;
    data['name'] = name;
    data['address'] = address;
    data['city'] = city;
    data['state'] = state;
    data['zip_code'] = zipCode;
    data['interstate'] = interstate;
    data['latitude'] = latitude ?? 0.0;
    data['longitude'] = longitude ?? 0.0;
    data['phone_number'] = phoneNumber;
    data['parking_spaces_count'] = parkingSpacesCount;
    data['fuel_lane_count'] = fuelLaneCount;
    data['shower_count'] = showerCount;
    data['amenities'] = amenities;
    data['restaurants'] = restaurants;
    if (fuelPrice != null) {
      data['latest_price'] = fuelPrice!.toJson();
    }
    return data;
  }

  // Helper method to get full address
  String get fullAddress {
    List<String> parts = [];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (zipCode != null && zipCode!.isNotEmpty) parts.add(zipCode!);
    return parts.join(', ');
  }

  // Helper method to get location string
  String get location {
    List<String> parts = [];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    return parts.join(', ');
  }
}

class FuelPrice {
  String? product;
  String? yourPrice;
  String? retailPrice;
  String? savingsTotal;
  String? effectiveDate;

  FuelPrice({
    this.product,
    this.yourPrice,
    this.retailPrice,
    this.savingsTotal,
    this.effectiveDate,
  });

  FuelPrice.fromJson(Map<String, dynamic> json) {
    product = json['product'];
    yourPrice = json['your_price'];
    retailPrice = json['retail_price'];
    savingsTotal = json['savings_total'];
    effectiveDate = json['effective_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product'] = product;
    data['your_price'] = yourPrice;
    data['retail_price'] = retailPrice;
    data['savings_total'] = savingsTotal;
    data['effective_date'] = effectiveDate;
    return data;
  }

  // Helper method to get formatted price
  String get formattedYourPrice {
    if (yourPrice == null || yourPrice!.isEmpty) return 'N/A';
    return '\$${yourPrice}';
  }

  String get formattedRetailPrice {
    if (retailPrice == null || retailPrice!.isEmpty) return 'N/A';
    return '\$${retailPrice}';
  }

  String get formattedSavings {
    if (savingsTotal == null || savingsTotal!.isEmpty) return 'N/A';
    return '\$${savingsTotal}';
  }
}
