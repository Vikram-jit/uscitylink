class DriverModel {
  String? id;
  String? phoneNumber;
  String? userType;
  String? driverNumber;
  int? yardId;
  String? email;
  String? status;
  String? createdAt;
  String? updatedAt;
  List<Profiles>? profiles;
  bool? isChannelExist;

  DriverModel(
      {this.id,
      this.phoneNumber,
      this.userType,
      this.driverNumber,
      this.yardId,
      this.email,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.profiles,
      this.isChannelExist});

  DriverModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    phoneNumber = json['phone_number'];
    userType = json['user_type'];
    driverNumber = json['driver_number'];
    yardId = json['yard_id'];
    email = json['email'];
    status = json['status'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    if (json['profiles'] != null) {
      profiles = <Profiles>[];
      json['profiles'].forEach((v) {
        profiles?.add(Profiles.fromJson(v));
      });
    }
    isChannelExist = json['isChannelExist'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['phone_number'] = this.phoneNumber;
    data['user_type'] = this.userType;
    data['driver_number'] = this.driverNumber;
    data['yard_id'] = this.yardId;
    data['email'] = this.email;
    data['status'] = this.status;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    if (this.profiles != null) {
      data['profiles'] = this.profiles?.map((v) => v.toJson()).toList();
    }
    data['isChannelExist'] = this.isChannelExist;
    return data;
  }
}

class Profiles {
  String? id;
  String? username;

  Profiles({this.id});

  Profiles.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['username'] = this.username;
    return data;
  }
}
