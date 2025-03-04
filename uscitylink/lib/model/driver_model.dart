class DriverModel {
  Driver? driver;
  CountryStatus? countryStatus;
  List<Document>? document;

  DriverModel({this.driver, this.document});

  DriverModel.fromJson(Map<String, dynamic> json) {
    driver =
        json['driver'] != null ? new Driver.fromJson(json['driver']) : null;
    countryStatus = json['countryStatus'] != null
        ? new CountryStatus.fromJson(json['countryStatus'])
        : null;
    if (json['document'] != null) {
      document = <Document>[];
      json['document'].forEach((v) {
        document?.add(new Document.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.driver != null) {
      data['driver'] = this.driver?.toJson();
    }
    if (this.countryStatus != null) {
      data['countryStatus'] = this.countryStatus?.toJson();
    }
    if (this.document != null) {
      data['document'] = this.document?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CountryStatus {
  int? id;
  int? driver_id;
  String? country_status;
  String? issue_date;
  String? expiry_date;
  String? document;

  CountryStatus({
    this.id,
    this.driver_id,
    this.country_status,
    this.issue_date,
    this.expiry_date,
    this.document,
  });

  CountryStatus.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    driver_id = json['driver_id'];
    country_status = json['country_status'];
    issue_date = json['issue_date'];
    expiry_date = json['expiry_date'];
    document = json['document'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['driver_id'] = this.driver_id;
    data['country_status'] = this.country_status;
    data['issue_date'] = this.issue_date;
    data['expiry_date'] = this.expiry_date;
    data['document'] = this.document;

    return data;
  }
}

class Driver {
  int? id;

  String? driverNumber;

  String? phoneNumber;
  String? name;

  String? email;

  Driver({
    this.id,
    this.driverNumber,
    this.phoneNumber,
    this.name,
    this.email,
  });

  Driver.fromJson(Map<String, dynamic> json) {
    id = json['id'];

    driverNumber = json['driver_number'];

    phoneNumber = json['phone_number'];
    name = json['name'];

    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;

    data['driver_number'] = this.driverNumber;

    data['phone_number'] = this.phoneNumber;
    data['name'] = this.name;

    data['email'] = this.email;

    return data;
  }
}

class Document {
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
  String? expired_status;

  Document(
      {this.id,
      this.itemId,
      this.type,
      this.title,
      this.file,
      this.issueDate,
      this.expireDate,
      this.createdAt,
      this.updatedAt,
      this.docType,
      this.expired_status});

  Document.fromJson(Map<String, dynamic> json) {
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
    expired_status = json['expired_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['item_id'] = this.itemId;
    data['type'] = this.type;
    data['title'] = this.title;
    data['file'] = this.file;
    data['expired_status'] = this.expired_status;
    data['issue_date'] = this.issueDate;
    data['expire_date'] = this.expireDate;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['doc_type'] = this.docType;
    return data;
  }
}
