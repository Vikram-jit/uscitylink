class SecurityDashboardModel {
  int? totalEntries;
  int? totalDepartures;
  String? date;

  SecurityDashboardModel({
    this.totalEntries,
    this.totalDepartures,
    this.date,
  });

  SecurityDashboardModel.fromJson(Map<String, dynamic> json) {
    totalEntries = json['totalEntries'];
    totalDepartures = json['totalDepartures'];
    date = json['date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['totalEntries'] = this.totalEntries;
    data['totalDepartures'] = this.totalDepartures;
    data['date'] = this.date;
    return data;
  }
}
