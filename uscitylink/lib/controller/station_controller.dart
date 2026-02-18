import 'package:get/get.dart';
import 'package:uscitylink/model/route_model.dart';

class StationGroup {
  final String stateCode;
  final String stateName;
  final List<Stations> stations;
  final int stationCount;

  StationGroup({
    required this.stateCode,
    required this.stateName,
    required this.stations,
  }) : stationCount = stations.length;

  // Add copyWith method if needed
  StationGroup copyWith({
    String? stateCode,
    String? stateName,
    List<Stations>? stations,
  }) {
    return StationGroup(
      stateCode: stateCode ?? this.stateCode,
      stateName: stateName ?? this.stateName,
      stations: stations ?? this.stations,
    );
  }
}

class StationController extends GetxController {
  // Add this method to your existing controller

  // Map of state codes to full state names (USA and Canada)
  static const Map<String, String> _stateNames = {
    // ===== USA =====
    "AL": "Alabama",
    "AK": "Alaska",
    "AZ": "Arizona",
    "AR": "Arkansas",
    "CA": "California",
    "CO": "Colorado",
    "CT": "Connecticut",
    "DE": "Delaware",
    "FL": "Florida",
    "GA": "Georgia",
    "HI": "Hawaii",
    "ID": "Idaho",
    "IL": "Illinois",
    "IN": "Indiana",
    "IA": "Iowa",
    "KS": "Kansas",
    "KY": "Kentucky",
    "LA": "Louisiana",
    "ME": "Maine",
    "MD": "Maryland",
    "MA": "Massachusetts",
    "MI": "Michigan",
    "MN": "Minnesota",
    "MS": "Mississippi",
    "MO": "Missouri",
    "MT": "Montana",
    "NE": "Nebraska",
    "NV": "Nevada",
    "NH": "New Hampshire",
    "NJ": "New Jersey",
    "NM": "New Mexico",
    "NY": "New York",
    "NC": "North Carolina",
    "ND": "North Dakota",
    "OH": "Ohio",
    "OK": "Oklahoma",
    "OR": "Oregon",
    "PA": "Pennsylvania",
    "RI": "Rhode Island",
    "SC": "South Carolina",
    "SD": "South Dakota",
    "TN": "Tennessee",
    "TX": "Texas",
    "UT": "Utah",
    "VT": "Vermont",
    "VA": "Virginia",
    "WA": "Washington",
    "WV": "West Virginia",
    "WI": "Wisconsin",
    "WY": "Wyoming",

    // ===== CANADA =====
    "AB": "Alberta",
    "BC": "British Columbia",
    "MB": "Manitoba",
    "NB": "New Brunswick",
    "NL": "Newfoundland and Labrador",
    "NS": "Nova Scotia",
    "NT": "Northwest Territories",
    "NU": "Nunavut",
    "ON": "Ontario",
    "PE": "Prince Edward Island",
    "QC": "Quebec",
    "SK": "Saskatchewan",
    "YT": "Yukon",
  };

  List<StationGroup> groupStationsByState(List<Stations> stations) {
    final Map<String, List<Stations>> grouped = {};

    for (var station in stations) {
      final stateCode = station.state ?? 'Unknown';
      if (!grouped.containsKey(stateCode)) {
        grouped[stateCode] = [];
      }
      grouped[stateCode]!.add(station);
    }

    final List<StationGroup> result = [];
    grouped.forEach((stateCode, stateStations) {
      final stateName = _getFullStateName(stateCode);
      result.add(StationGroup(
        // Now using imported StationGroup
        stateCode: stateCode,
        stateName: stateName,
        stations: stateStations,
      ));
    });

    result.sort((a, b) => a.stateName.compareTo(b.stateName));
    return result;
  }

  String _getFullStateName(String stateCode) {
    return _stateNames[stateCode] ?? stateCode; // Return code if not found
  }

  Map<String, List<Stations>> getStationsByStateMap(List<Stations> stations) {
    final Map<String, List<Stations>> result = {};

    for (var station in stations) {
      final stateCode = station.state ?? 'Unknown';
      final stateName = _getFullStateName(stateCode);

      if (!result.containsKey(stateName)) {
        result[stateName] = [];
      }
      result[stateName]!.add(station);
    }

    final sortedKeys = result.keys.toList()..sort();
    final Map<String, List<Stations>> sortedMap = {};
    for (var key in sortedKeys) {
      sortedMap[key] = result[key]!;
    }

    return sortedMap;
  }

  Map<String, int> getStateWiseStationCounts(List<Stations> stations) {
    final Map<String, int> counts = {};

    for (var station in stations) {
      final stateCode = station.state ?? 'Unknown';
      final stateName = _getFullStateName(stateCode);

      counts[stateName] = (counts[stateName] ?? 0) + 1;
    }

    // Sort by count descending
    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  List<Stations> getStationsByState(List<Stations> stations, String stateCode) {
    final fullStateName = _getFullStateName(stateCode);
    return stations
        .where((s) =>
            s.state == stateCode ||
            (fullStateName != stateCode && s.state == fullStateName))
        .toList();
  }

  // Method 6: Format state code to full name (single utility function)
  String getStateFullName(String? stateCode) {
    if (stateCode == null || stateCode.isEmpty) return 'Unknown';
    return _stateNames[stateCode] ?? stateCode;
  }
}
