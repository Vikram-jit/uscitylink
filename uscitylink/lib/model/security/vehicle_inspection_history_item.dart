import 'package:uscitylink/model/pagination_model.dart';

class VehicleInspectionHistoryItem {
  int? id;
  String? inspectedAt;
  String? companyName;
  String? driverNames;
  String? note;
  String? addedBy;
  String? truckNumber;
  String? trailerNumber;
  int okCount;
  int problemCount;

  VehicleInspectionHistoryItem({
    this.id,
    this.inspectedAt,
    this.companyName,
    this.driverNames,
    this.note,
    this.addedBy,
    this.truckNumber,
    this.trailerNumber,
    this.okCount = 0,
    this.problemCount = 0,
  });

  VehicleInspectionHistoryItem.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        inspectedAt = json['inspectedAt'],
        companyName = json['companyName'],
        driverNames = json['driverNames'],
        note = json['note'],
        addedBy = json['addedBy'],
        truckNumber = json['truckNumber']?.toString(),
        trailerNumber = json['trailerNumber']?.toString(),
        okCount = json['okCount'] ?? 0,
        problemCount = json['problemCount'] ?? 0;
}

class VehicleInspectionHistoryPage {
  List<VehicleInspectionHistoryItem> inspections;
  PaginationModel? pagination;

  VehicleInspectionHistoryPage({this.inspections = const [], this.pagination});

  VehicleInspectionHistoryPage.fromJson(Map<String, dynamic> json)
      : inspections = (json['inspections'] as List<dynamic>? ?? [])
            .map((e) => VehicleInspectionHistoryItem.fromJson(e))
            .toList(),
        pagination = json['pagination'] != null
            ? PaginationModel.fromJson(json['pagination'])
            : null;
}
