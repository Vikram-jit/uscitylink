class VehicleModel {
  int? id;

  String? number;
  int? year;
  String? make;
  String? model;
  String? vin;
  String? licensePlateNumber;
  String? state;
  String? type;
  String? currentPosition;
  String? readyStatus;
  String? pre_pass_id;
  String? driver_fuel_id;
  String? fuel_card_number;

  List<Documents>? documents;

  VehicleModel(
      {this.id,
      this.number,
      this.year,
      this.make,
      this.model,
      this.vin,
      this.licensePlateNumber,
      this.state,
      this.type,
      this.currentPosition,
      this.readyStatus,
      this.documents,
      this.pre_pass_id,
      this.driver_fuel_id,
      this.fuel_card_number});

  VehicleModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    pre_pass_id = json['pre_pass_id'];
    driver_fuel_id = json['driver_fuel_id'];
    fuel_card_number = json['fuel_card_number'];
    number = json['number'];
    year = json['year'];
    make = json['make'];
    model = json['model'];
    vin = json['vin'];
    licensePlateNumber = json['license_plate_number'];
    state = json['state'];
    type = json['type'];
    currentPosition = json['current_position'];
    readyStatus = json['ready_status'];

    if (json['documents'] != null) {
      documents = <Documents>[];
      json['documents'].forEach((v) {
        documents!.add(new Documents.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['pre_pass_id'] = this.pre_pass_id;
    data['driver_fuel_id'] = this.driver_fuel_id;
    data['fuel_card_number'] = this.fuel_card_number;
    data['number'] = this.number;
    data['year'] = this.year;
    data['make'] = this.make;
    data['model'] = this.model;
    data['vin'] = this.vin;
    data['license_plate_number'] = this.licensePlateNumber;
    data['state'] = this.state;
    data['type'] = this.type;
    data['current_position'] = this.currentPosition;
    data['ready_status'] = this.readyStatus;

    if (this.documents != null) {
      data['documents'] = this.documents!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Documents {
  int? id;
  int? itemId;
  String? type;
  String? title;
  String? file;
  String? issueDate;
  String? expireDate;
  String? createdAt;
  String? updatedAt;
  String? docType;

  Documents(
      {this.id,
      this.itemId,
      this.type,
      this.title,
      this.file,
      this.issueDate,
      this.expireDate,
      this.createdAt,
      this.updatedAt,
      this.docType});

  Documents.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    itemId = json['item_id'];
    type = json['type'];
    title = json['title'];
    file = json['file'];
    issueDate = json['issue_date'];
    expireDate = json['expire_date'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    docType = json['doc_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['item_id'] = this.itemId;
    data['type'] = this.type;
    data['title'] = this.title;
    data['file'] = this.file;
    data['issue_date'] = this.issueDate;
    data['expire_date'] = this.expireDate;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['doc_type'] = this.docType;
    return data;
  }
}
