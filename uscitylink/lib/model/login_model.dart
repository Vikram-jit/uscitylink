import 'package:uscitylink/model/staff/channel_chat_user_model.dart';
import 'package:uscitylink/model/user_model.dart';
import 'package:uscitylink/model/vehicle_model.dart';

class LoginModel {
  String? id;
  String? phoneNumber;
  String? email;
  String? status;
  String? createdAt;
  String? updatedAt;
  List<Profiles>? profiles;

  LoginModel({
    this.id,
    this.phoneNumber,
    this.email,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.profiles,
  });

  // Factory constructor to create a LoginModel from JSON
  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      id: json['id'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      status: json['status'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      profiles: json['profiles'] != null
          ? List<Profiles>.from(
              json['profiles'].map((v) => Profiles.fromJson(v)))
          : null,
    );
  }

  // Convert LoginModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'email': email,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'profiles': profiles?.map((v) => v.toJson()).toList(),
    };
  }
}

class Profiles {
  String? id;
  String? userId;
  String? username;
  String? profilePic;
  String? status;
  String? roleId;
  String? lastMessageId;
  bool? isOnline;
  String? deviceId;
  String? deviceToken;
  String? platform;
  String? lastLogin;
  String? createdAt;
  String? updatedAt;
  String? version;
  String? buildNumber;
  String? appUpdate;
  List<Documents>? documents;

  Role? role;
  UserModel? user;

  Profiles(
      {this.id,
      this.userId,
      this.username,
      this.profilePic,
      this.status,
      this.roleId,
      this.lastMessageId,
      this.isOnline,
      this.deviceId,
      this.deviceToken,
      this.platform,
      this.lastLogin,
      this.createdAt,
      this.updatedAt,
      this.role,
      this.user,
      this.appUpdate,
      this.buildNumber,
      this.version,
      this.documents});

  // Factory constructor to create a Profiles from JSON
  factory Profiles.fromJson(Map<String, dynamic> json) {
    return Profiles(
      id: json['id'],
      userId: json['userId'],
      username: json['username'],
      profilePic: json['profile_pic'],
      status: json['status'],
      roleId: json['role_id'],
      lastMessageId: json['last_message_id'],
      isOnline: json['isOnline'],
      deviceId: json['device_id'],
      deviceToken: json['device_token'],
      platform: json['platform'],
      lastLogin: json['last_login'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      buildNumber: json['buildNumber'],
      version: json['version'],
      appUpdate: json['appUpdate'],
      role: json['role'] != null ? Role.fromJson(json['role']) : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      documents: json['documents'] != null
          ? List<Documents>.from(
              json['documents'].map((v) => Documents.fromJson(v)))
          : null,
    );
  }

  // Convert Profiles to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'profile_pic': profilePic,
      'status': status,
      'role_id': roleId,
      'last_message_id': lastMessageId,
      'isOnline': isOnline,
      'device_id': deviceId,
      'device_token': deviceToken,
      'platform': platform,
      'last_login': lastLogin,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'buildNumber': buildNumber,
      'appUpdate': appUpdate,
      'version': version,
      'role': role?.toJson(),
      'user': user?.toJson(),
      'documents': documents?.map((v) => v.toJson()).toList(),
    };
  }
}

class Role {
  String? id;
  String? name;
  String? createdAt;
  String? updatedAt;

  Role({this.id, this.name, this.createdAt, this.updatedAt});

  // Factory constructor to create a Role from JSON
  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  // Convert Role to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class LoginWithPasswordModel {
  String? access_token;

  Profiles? profiles;

  LoginWithPasswordModel({this.access_token, this.profiles});

  factory LoginWithPasswordModel.fromJson(Map<String, dynamic> json) {
    return LoginWithPasswordModel(
      access_token: json['access_toke'],
      profiles: json['user'] != null ? Profiles.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': access_token,
      'user': profiles?.toJson(),
    };
  }
}

class OTP {
  String? email;
  String? phone_number;
  bool? isEmail;
  bool? isPhoneNumber;

  OTP({this.email, this.phone_number, this.isEmail, this.isPhoneNumber});

  // Factory constructor to create a Role from JSON
  factory OTP.fromJson(Map<String, dynamic> json) {
    return OTP(
      email: json['email'],
      isEmail: json['isEmail'],
      isPhoneNumber: json['isPhoneNumber'],
      phone_number: json['phone_number'],
    );
  }

  // Convert Role to JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'isEmail': isEmail,
      'isPhoneNumber': isPhoneNumber,
      'phone_number': phone_number,
    };
  }
}
