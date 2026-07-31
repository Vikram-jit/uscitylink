class ReadyTrailerOption {
  int? id;
  String? number;

  ReadyTrailerOption({this.id, this.number});

  ReadyTrailerOption.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    number = json['number']?.toString();
  }
}

/// Response of POST /security/entries/check-trailer-status — mirrors
/// DailyVehicleEntryController::checkTrailerStatus() exactly.
class TrailerStatusCheckResult {
  bool blocked;
  String? trailerNumber;
  String? emptyLoaded;
  String? readyStatus;
  List<ReadyTrailerOption> readyTrailers;

  TrailerStatusCheckResult({
    this.blocked = false,
    this.trailerNumber,
    this.emptyLoaded,
    this.readyStatus,
    this.readyTrailers = const [],
  });

  TrailerStatusCheckResult.fromJson(Map<String, dynamic> json)
      : blocked = json['blocked'] == true,
        trailerNumber = json['trailerNumber']?.toString(),
        emptyLoaded = json['emptyLoaded'],
        readyStatus = json['readyStatus'],
        readyTrailers = (json['readyTrailers'] as List<dynamic>? ?? [])
            .map((e) => ReadyTrailerOption.fromJson(e))
            .toList();
}
