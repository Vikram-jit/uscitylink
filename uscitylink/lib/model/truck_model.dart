import 'package:uscitylink/model/pagination_model.dart';

class TruckModel {
  List<Truck>? data;
  PaginationModel? pagination;

  TruckModel({this.data, this.pagination});

  TruckModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Truck>[];
      json['data'].forEach((v) {
        data?.add(new Truck.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new PaginationModel.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data?.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination?.toJson();
    }
    return data;
  }
}

class Truck {
  int? id;

  String? number;

  Truck({
    this.id,
    this.number,
  });

  Truck.fromJson(Map<String, dynamic> json) {
    id = json['id'];

    number = json['number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;

    data['number'] = this.number;

    return data;
  }
}
