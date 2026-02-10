// Main route model
class RouteModel {
  final int id;
  final String fromLocation;
  final String toLocation;
  final double distance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LocationDetails fromDetails;
  final LocationDetails toDetails;
  final List<Truck> trucks;
  final List<Station> stations;

  RouteModel({
    required this.id,
    required this.fromLocation,
    required this.toLocation,
    required this.distance,
    required this.createdAt,
    required this.updatedAt,
    required this.fromDetails,
    required this.toDetails,
    required this.trucks,
    required this.stations,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'],
      fromLocation: json['from_location'],
      toLocation: json['to_location'],
      distance: (json['distance'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      fromDetails: LocationDetails.fromJson({
        'address': json['from_address'],
        'city': json['from_city'],
        'state': json['from_state'],
        'zip': json['from_zip'],
        'country': json['from_country'],
        'lat': json['from_lat'],
        'lng': json['from_lng'],
      }),
      toDetails: LocationDetails.fromJson({
        'address': json['to_address'],
        'city': json['to_city'],
        'state': json['to_state'],
        'zip': json['to_zip'],
        'country': json['to_country'],
        'lat': json['to_lat'],
        'lng': json['to_lng'],
      }),
      trucks: (json['trucks'] as List)
          .map((truck) => Truck.fromJson(truck))
          .toList(),
      stations: (json['stations'] as List)
          .map((station) => Station.fromJson(station))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_location': fromLocation,
      'to_location': toLocation,
      'distance': distance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'from_address': fromDetails.address,
      'from_city': fromDetails.city,
      'from_state': fromDetails.state,
      'from_zip': fromDetails.zip,
      'from_country': fromDetails.country,
      'from_lat': fromDetails.lat,
      'from_lng': fromDetails.lng,
      'to_address': toDetails.address,
      'to_city': toDetails.city,
      'to_state': toDetails.state,
      'to_zip': toDetails.zip,
      'to_country': toDetails.country,
      'to_lat': toDetails.lat,
      'to_lng': toDetails.lng,
      'trucks': trucks.map((truck) => truck.toJson()).toList(),
      'stations': stations.map((station) => station.toJson()).toList(),
    };
  }
}

// Location details model
class LocationDetails {
  final String address;
  final String? city;
  final String state;
  final String? zip;
  final String country;
  final double lat;
  final double lng;

  LocationDetails({
    required this.address,
    this.city,
    required this.state,
    this.zip,
    required this.country,
    required this.lat,
    required this.lng,
  });

  factory LocationDetails.fromJson(Map<String, dynamic> json) {
    return LocationDetails(
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zip: json['zip'],
      country: json['country'],
      lat: double.parse(json['lat'].toString()),
      lng: double.parse(json['lng'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
      'lat': lat.toString(),
      'lng': lng.toString(),
    };
  }
}

// Truck model
class Truck {
  final int id;
  final String number;

  Truck({
    required this.id,
    required this.number,
  });

  factory Truck.fromJson(Map<String, dynamic> json) {
    return Truck(
      id: json['id'],
      number: json['number'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
    };
  }
}

// Station model
class Station {
  final int id;
  final int storeNumber;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String interstate;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final int parkingSpacesCount;
  final int fuelLaneCount;
  final int showerCount;
  final List<String> amenities;
  final List<String> restaurants;
  final FuelPrice? latestPrice;

  Station({
    required this.id,
    required this.storeNumber,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.interstate,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.parkingSpacesCount,
    required this.fuelLaneCount,
    required this.showerCount,
    required this.amenities,
    required this.restaurants,
    this.latestPrice,
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
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phoneNumber: json['phone_number'],
      parkingSpacesCount: json['parking_spaces_count'],
      fuelLaneCount: json['fuel_lane_count'],
      showerCount: json['shower_count'],
      amenities: (json['amenities'] as String).split(' | '),
      restaurants: (json['restaurants'] as String).split(' | '),
      latestPrice: json['latest_price'] != null
          ? FuelPrice.fromJson(json['latest_price'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_number': storeNumber,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'interstate': interstate,
      'latitude': latitude,
      'longitude': longitude,
      'phone_number': phoneNumber,
      'parking_spaces_count': parkingSpacesCount,
      'fuel_lane_count': fuelLaneCount,
      'shower_count': showerCount,
      'amenities': amenities.join(' | '),
      'restaurants': restaurants.join(' | '),
      'latest_price': latestPrice?.toJson(),
    };
  }
}

// Fuel price model
class FuelPrice {
  final String product;
  final double yourPrice;
  final double retailPrice;
  final double savingsTotal;
  final DateTime effectiveDate;

  FuelPrice({
    required this.product,
    required this.yourPrice,
    required this.retailPrice,
    required this.savingsTotal,
    required this.effectiveDate,
  });

  factory FuelPrice.fromJson(Map<String, dynamic> json) {
    return FuelPrice(
      product: json['product'],
      yourPrice: (json['your_price'] as num).toDouble(),
      retailPrice: (json['retail_price'] as num).toDouble(),
      savingsTotal: (json['savings_total'] as num).toDouble(),
      effectiveDate: DateTime.parse(json['effective_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product,
      'your_price': yourPrice,
      'retail_price': retailPrice,
      'savings_total': savingsTotal,
      'effective_date': effectiveDate.toIso8601String(),
    };
  }
}
