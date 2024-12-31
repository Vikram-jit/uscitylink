class ChannelMemberModel {
  String? id;
  String? userProfileId;
  String? channelId;
  String? lastMessageId;
  int? recieveMessageCount;
  String? status;
  int? sentMessageCount;
  String? lastMessageUtc;
  String? createdAt;
  String? updatedAt;
  UserProfile? userProfile;

  ChannelMemberModel(
      {this.id,
      this.userProfileId,
      this.channelId,
      this.lastMessageId,
      this.recieveMessageCount,
      this.status,
      this.sentMessageCount,
      this.lastMessageUtc,
      this.createdAt,
      this.updatedAt,
      this.userProfile});

  ChannelMemberModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userProfileId = json['userProfileId'];
    channelId = json['channelId'];
    lastMessageId = json['last_message_id'];
    recieveMessageCount = json['recieve_message_count'];
    status = json['status'];
    sentMessageCount = json['sent_message_count'];
    lastMessageUtc = json['last_message_utc'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    userProfile = json['UserProfile'] != null
        ? new UserProfile.fromJson(json['UserProfile'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['userProfileId'] = this.userProfileId;
    data['channelId'] = this.channelId;
    data['last_message_id'] = this.lastMessageId;
    data['recieve_message_count'] = this.recieveMessageCount;
    data['status'] = this.status;
    data['sent_message_count'] = this.sentMessageCount;
    data['last_message_utc'] = this.lastMessageUtc;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    if (this.userProfile != null) {
      data['UserProfile'] = this.userProfile?.toJson();
    }
    return data;
  }
}

class UserProfile {
  String? id;
  String? userId;
  String? username;
  String? profilePic;
  String? password;
  String? status;
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
  User? user;

  UserProfile(
      {this.id,
      this.userId,
      this.username,
      this.profilePic,
      this.password,
      this.status,
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
      this.user});

  UserProfile.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    username = json['username'];
    profilePic = json['profile_pic'];
    password = json['password'];
    status = json['status'];
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
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['userId'] = this.userId;
    data['username'] = this.username;
    data['profile_pic'] = this.profilePic;
    data['password'] = this.password;
    data['status'] = this.status;
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
      data['user'] = this.user?.toJson();
    }
    return data;
  }
}

class User {
  String? id;
  String? phoneNumber;
  String? userType;
  String? driverNumber;
  int? yardId;
  String? email;
  String? status;
  String? createdAt;
  String? updatedAt;

  User(
      {this.id,
      this.phoneNumber,
      this.userType,
      this.driverNumber,
      this.yardId,
      this.email,
      this.status,
      this.createdAt,
      this.updatedAt});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    phoneNumber = json['phone_number'];
    userType = json['user_type'];
    driverNumber = json['driver_number'];
    yardId = json['yard_id'];
    email = json['email'];
    status = json['status'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
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
    return data;
  }
}
