class HosStatusModel {
  String? dutyStatus;
  String? dutyStatusSince;
  int? driveRemainingMinutes;
  int? driveElapsedMinutes;
  int? driveLimitMinutes;
  int? onDutyRemainingMinutes;
  int? onDutyElapsedMinutes;
  int? onDutyLimitMinutes;
  int? cycleRemainingMinutes;
  int? cycleUsedMinutes;
  int? cycleLimitMinutes;
  String? cycleLabel;
  int? breakInMinutes;

  HosStatusModel({
    this.dutyStatus,
    this.dutyStatusSince,
    this.driveRemainingMinutes,
    this.driveElapsedMinutes,
    this.driveLimitMinutes,
    this.onDutyRemainingMinutes,
    this.onDutyElapsedMinutes,
    this.onDutyLimitMinutes,
    this.cycleRemainingMinutes,
    this.cycleUsedMinutes,
    this.cycleLimitMinutes,
    this.cycleLabel,
    this.breakInMinutes,
  });

  HosStatusModel.fromJson(Map<String, dynamic> json) {
    dutyStatus = json['dutyStatus'];
    dutyStatusSince = json['dutyStatusSince'];
    driveRemainingMinutes = json['driveRemainingMinutes'];
    driveElapsedMinutes = json['driveElapsedMinutes'];
    driveLimitMinutes = json['driveLimitMinutes'];
    onDutyRemainingMinutes = json['onDutyRemainingMinutes'];
    onDutyElapsedMinutes = json['onDutyElapsedMinutes'];
    onDutyLimitMinutes = json['onDutyLimitMinutes'];
    cycleRemainingMinutes = json['cycleRemainingMinutes'];
    cycleUsedMinutes = json['cycleUsedMinutes'];
    cycleLimitMinutes = json['cycleLimitMinutes'];
    cycleLabel = json['cycleLabel'];
    breakInMinutes = json['breakInMinutes'];
  }
}
