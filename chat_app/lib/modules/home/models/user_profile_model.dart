import 'package:chat_app/modules/home/models/user_model.dart';

class UserProfileModel {
  String? id;
  String? userId;
  String? username;
  String? profilePic;
  String? status;
  String? version;
  String? buildNumber;
  String? appUpdate;
  String? roleId;
  String? lastMessageId;
  bool? isOnline;
  String? deviceId;
  String? deviceToken;
  String? platform;
  String? lastLogin;
  String? channelId;
  String? createdAt;
  String? updatedAt;
  UserModel? user;

  UserProfileModel({
    this.id,
    this.userId,
    this.username,
    this.profilePic,
    this.status,
    this.version,
    this.buildNumber,
    this.appUpdate,
    this.roleId,
    this.lastMessageId,
    this.isOnline,
    this.deviceId,
    this.deviceToken,
    this.platform,
    this.lastLogin,
    this.channelId,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  UserProfileModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    username = json['username'];
    profilePic = json['profile_pic'];
    status = json['status'];
    version = json['version'];
    buildNumber = json['buildNumber'];
    appUpdate = json['appUpdate'];
    roleId = json['role_id'];
    lastMessageId = json['last_message_id'];
    isOnline = json['isOnline'];
    deviceId = json['device_id'];
    deviceToken = json['device_token'];
    platform = json['platform'];
    lastLogin = json['last_login'];
    channelId = json['channelId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    user = json['user'] != null ? new UserModel.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['userId'] = this.userId;
    data['username'] = this.username;
    data['profile_pic'] = this.profilePic;
    data['status'] = this.status;
    data['version'] = this.version;
    data['buildNumber'] = this.buildNumber;
    data['appUpdate'] = this.appUpdate;
    data['role_id'] = this.roleId;
    data['last_message_id'] = this.lastMessageId;
    data['isOnline'] = this.isOnline;
    data['device_id'] = this.deviceId;
    data['device_token'] = this.deviceToken;
    data['platform'] = this.platform;
    data['last_login'] = this.lastLogin;
    data['channelId'] = this.channelId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    return data;
  }
}
