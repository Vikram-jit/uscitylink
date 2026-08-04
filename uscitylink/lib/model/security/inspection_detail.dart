import 'package:uscitylink/model/security/inspection_question_answer.dart';

class InspectionDetail {
  int? id;
  String? inspectedAt;
  String? companyName;
  String? odometer;
  String? driverNames;
  String? note;
  String? addedBy;
  String? vehicleType;
  String? truckNumber;
  String? trailerNumber;
  List<InspectionQuestionAnswer> truckAnswers;
  List<InspectionQuestionAnswer> trailerAnswers;

  InspectionDetail({
    this.id,
    this.inspectedAt,
    this.companyName,
    this.odometer,
    this.driverNames,
    this.note,
    this.addedBy,
    this.vehicleType,
    this.truckNumber,
    this.trailerNumber,
    this.truckAnswers = const [],
    this.trailerAnswers = const [],
  });

  InspectionDetail.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        inspectedAt = json['inspectedAt'],
        companyName = json['companyName'],
        odometer = json['odometer']?.toString(),
        driverNames = json['driverNames'],
        note = json['note'],
        addedBy = json['addedBy'],
        vehicleType = json['vehicleType'],
        truckNumber = json['truckNumber']?.toString(),
        trailerNumber = json['trailerNumber']?.toString(),
        truckAnswers = (json['truckAnswers'] as List<dynamic>? ?? [])
            .map((e) => InspectionQuestionAnswer.fromJson(e))
            .toList(),
        trailerAnswers = (json['trailerAnswers'] as List<dynamic>? ?? [])
            .map((e) => InspectionQuestionAnswer.fromJson(e))
            .toList();

  bool get hasTrailer => trailerNumber != null;
}
