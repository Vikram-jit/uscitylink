class AuthModel {
  String? accessToken;
  User? user;

  AuthModel({this.accessToken, this.user});

  AuthModel.fromJson(Map<String, dynamic> json) {
    accessToken = json['access_token'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['access_token'] = this.accessToken;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    return data;
  }
}

class User {
  String? id;
  String? userId;
  String? username;
  Null? profilePic;
  String? password;
  String? status;
  String? version;
  String? buildNumber;
  String? appUpdate;
  String? roleId;
  Null? lastMessageId;
  bool? isOnline;
  Null? deviceId;
  Null? deviceToken;
  String? platform;
  String? lastLogin;
  String? channelId;
  String? createdAt;
  String? updatedAt;
  Role? role;

  User({
    this.id,
    this.userId,
    this.username,
    this.profilePic,
    this.password,
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
    this.role,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    username = json['username'];
    profilePic = json['profile_pic'];
    password = json['password'];
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
    role = json['role'] != null ? new Role.fromJson(json['role']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['userId'] = this.userId;
    data['username'] = this.username;
    data['profile_pic'] = this.profilePic;
    data['password'] = this.password;
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
    if (this.role != null) {
      data['role'] = this.role!.toJson();
    }
    return data;
  }
}

class Role {
  String? id;
  String? name;
  String? createdAt;
  String? updatedAt;

  Role({this.id, this.name, this.createdAt, this.updatedAt});

  Role.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
