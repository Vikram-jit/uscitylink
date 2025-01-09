class TruckModel {
  String? number;

  TruckModel({
    this.number,
  });

  TruckModel.fromJson(Map<String, dynamic> json) {
    number = json['number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    data['number'] = this.number;

    return data;
  }
}
