class SecurityDriverModel {
  int? id;
  String? name;

  SecurityDriverModel({this.id, this.name});

  SecurityDriverModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }
}
