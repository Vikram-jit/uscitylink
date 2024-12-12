class TruckModel {
  List<Truck>? data;
  Pagination? pagination;

  TruckModel({this.data, this.pagination});

  TruckModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Truck>[];
      json['data'].forEach((v) {
        data?.add(new Truck.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
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

class Pagination {
  int? currentPage;
  int? pageSize;
  int? totalPages;
  int? totalItems;

  Pagination(
      {this.currentPage, this.pageSize, this.totalPages, this.totalItems});

  Pagination.fromJson(Map<String, dynamic> json) {
    currentPage = json['currentPage'];
    pageSize = json['pageSize'];
    totalPages = json['totalPages'];
    totalItems = json['totalItems'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['currentPage'] = this.currentPage;
    data['pageSize'] = this.pageSize;
    data['totalPages'] = this.totalPages;
    data['totalItems'] = this.totalItems;
    return data;
  }
}
