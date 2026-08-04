import 'package:uscitylink/model/pagination_model.dart';

class VehicleInspectionListItem {
  int? id;
  String? number;
  String? lastInspectedAt;
  bool isDone;
  int okCount;
  int problemCount;

  VehicleInspectionListItem({
    this.id,
    this.number,
    this.lastInspectedAt,
    this.isDone = false,
    this.okCount = 0,
    this.problemCount = 0,
  });

  VehicleInspectionListItem.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        number = json['number']?.toString(),
        lastInspectedAt = json['lastInspectedAt'],
        isDone = json['isDone'] == true,
        okCount = json['okCount'] ?? 0,
        problemCount = json['problemCount'] ?? 0;
}

class VehicleInspectionListPage {
  List<VehicleInspectionListItem> vehicles;
  PaginationModel? pagination;

  VehicleInspectionListPage({this.vehicles = const [], this.pagination});

  VehicleInspectionListPage.fromJson(Map<String, dynamic> json)
      : vehicles = (json['vehicles'] as List<dynamic>? ?? [])
            .map((e) => VehicleInspectionListItem.fromJson(e))
            .toList(),
        pagination = json['pagination'] != null
            ? PaginationModel.fromJson(json['pagination'])
            : null;
}
