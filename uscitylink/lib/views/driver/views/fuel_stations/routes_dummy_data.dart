import 'package:uscitylink/model/route_model.dart';

final List<Map<String, dynamic>> routesRawDummyData = [
  {
    "id": 8,
    "from_location": "Birmingham, AL, USA",
    "to_location": "Hope Hull, AL, USA",
    "distance": 98,
    "created_at": "2026-02-05T01:24:57.000Z",
    "updated_at": "2026-02-05T01:24:57.000Z",
    "from_address": "Birmingham, AL, USA",
    "from_city": "Birmingham",
    "from_state": "Alabama",
    "from_zip": null,
    "from_country": "United States",
    "from_lat": "33.5185892",
    "from_lng": "-86.8103567",
    "to_address": "Hope Hull, AL, USA",
    "to_city": null,
    "to_state": "Alabama",
    "to_zip": "36043",
    "to_country": "United States",
    "to_lat": "32.2695189",
    "to_lng": "-86.3567376",
    "trucks": [
      {"id": 144, "number": "30965"}
    ],
    "stations": [
      {
        "id": 211,
        "store_number": 602,
        "name": "Pilot Travel Center",
        "address": "224 Daniel Payne Dr",
        "city": "Birmingham",
        "state": "AL",
        "zip_code": "35207",
        "interstate": "I-65, Exit 264",
        "latitude": 33.56259486,
        "longitude": -86.83074712,
        "phone_number": "(205) 323-2177",
        "parking_spaces_count": 157,
        "fuel_lane_count": 12,
        "shower_count": 12,
        "amenities":
            "Diesel Lanes | Showers | Prime Parking Spaces | Diesel Mobile Fueling | Premium Wifi | ATM | Bulk Propane | CAT Scale | Cylinder Propane | DEF Lanes | Drivers Lounge | Game Room | Pegasus | Public Laundry | Truck Parking Spaces | Bridgestone Tire Monitoring",
        "restaurants": "Cinnabon",
        "latest_price": {
          "product": "DSL",
          "your_price": 3.0126,
          "retail_price": 3.699,
          "savings_total": 0.6864,
          "effective_date": "2026-01-30"
        }
      },
      {
        "id": 238,
        "store_number": 604,
        "name": "Flying J Travel Center",
        "address": "900 Tyson Rd",
        "city": "Hope Hull",
        "state": "AL",
        "zip_code": "36043",
        "interstate": "I-65, Exit 158",
        "latitude": 32.19420291,
        "longitude": -86.41967308,
        "phone_number": "(334) 613-0212",
        "parking_spaces_count": 145,
        "fuel_lane_count": 8,
        "shower_count": 7,
        "amenities":
            "Diesel Lanes | Showers | Prime Parking Spaces | Diesel Mobile Fueling | Premium Wifi | ATM | Bulk Propane | CAT Scale | Cylinder Propane | DEF Lanes | Game Room | Pegasus | Public Laundry | Truck Parking Spaces | Electric Vehicle Charging Station | Bridgestone Tire Monitoring | Southern Tire Mart at Pilot / Truck Care",
        "restaurants": "Cinnabon",
        "latest_price": {
          "product": "DSL",
          "your_price": 3.035,
          "retail_price": 3.759,
          "savings_total": 0.724,
          "effective_date": "2026-01-30"
        }
      }
    ]
  }
];

/// Convert RAW MAP → MODEL
final List<RouteModel> dummyRoutes =
    routesRawDummyData.map((e) => RouteModel.fromJson(e)).toList();
