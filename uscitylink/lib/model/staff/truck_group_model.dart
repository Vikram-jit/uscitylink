import 'package:uscitylink/model/message_model.dart';

class TruckGroupModel {
  Group? group;
  List<Members>? members;
  List<MessageModel>? messages;
  Pagination? pagination;

  TruckGroupModel({this.group, this.members, this.messages, this.pagination});

  TruckGroupModel.fromJson(Map<String, dynamic> json) {
    group = json['group'] != null ? new Group.fromJson(json['group']) : null;
    if (json['members'] != null) {
      members = <Members>[];
      json['members'].forEach((v) {
        members?.add(new Members.fromJson(v));
      });
    }
    if (json['messages'] != null) {
      messages = <MessageModel>[];
      json['messages'].forEach((v) {
        messages?.add(new MessageModel.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.group != null) {
      data['group'] = this.group?.toJson();
    }
    if (this.members != null) {
      data['members'] = this.members?.map((v) => v.toJson()).toList();
    }
    if (this.messages != null) {
      data['messages'] = this.messages?.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination?.toJson();
    }
    return data;
  }
}

class Group {
  String? id;
  String? name;
  String? description;
  String? type;
  String? lastMessageId;
  int? messageCount;
  String? createdAt;
  String? updatedAt;

  Group(
      {this.id,
      this.name,
      this.description,
      this.type,
      this.lastMessageId,
      this.messageCount,
      this.createdAt,
      this.updatedAt});

  Group.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    type = json['type'];
    lastMessageId = json['last_message_id'];
    messageCount = json['message_count'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
    data['type'] = this.type;
    data['last_message_id'] = this.lastMessageId;
    data['message_count'] = this.messageCount;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}

class Members {
  String? id;
  String? groupId;
  String? userProfileId;
  String? status;
  String? lastMessageId;
  int? messageCount;
  String? lastMessageUtc;
  String? createdAt;
  String? updatedAt;
  UserProfile? userProfile;

  Members(
      {this.id,
      this.groupId,
      this.userProfileId,
      this.status,
      this.lastMessageId,
      this.messageCount,
      this.lastMessageUtc,
      this.createdAt,
      this.updatedAt,
      this.userProfile});

  Members.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    groupId = json['groupId'];
    userProfileId = json['userProfileId'];
    status = json['status'];
    lastMessageId = json['last_message_id'];
    messageCount = json['message_count'];
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
    data['groupId'] = this.groupId;
    data['userProfileId'] = this.userProfileId;
    data['status'] = this.status;
    data['last_message_id'] = this.lastMessageId;
    data['message_count'] = this.messageCount;
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

class Messages {
  String? id;
  String? groupId;
  String? senderId;
  String? body;
  String? deliveryStatus;
  String? messageTimestampUtc;
  String? url;
  String? thumbnail;
  String? createdAt;
  String? updatedAt;
  Sender? sender;
  String? url_upload_type;

  Messages(
      {this.id,
      this.groupId,
      this.senderId,
      this.body,
      this.deliveryStatus,
      this.messageTimestampUtc,
      this.url,
      this.createdAt,
      this.updatedAt,
      this.sender,
      this.thumbnail,
      this.url_upload_type});

  Messages.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    groupId = json['groupId'];
    url_upload_type = json['url_upload_type'];
    senderId = json['senderId'];
    body = json['body'];
    deliveryStatus = json['deliveryStatus'];
    messageTimestampUtc = json['messageTimestampUtc'];
    url = json['url'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    thumbnail = json['thumbnail'];
    sender =
        json['sender'] != null ? new Sender.fromJson(json['sender']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['url_upload_type'] = this.url_upload_type;
    data['groupId'] = this.groupId;
    data['senderId'] = this.senderId;
    data['body'] = this.body;
    data['deliveryStatus'] = this.deliveryStatus;
    data['messageTimestampUtc'] = this.messageTimestampUtc;
    data['url'] = this.url;
    data['createdAt'] = this.createdAt;
    data['thumbnail'] = thumbnail;
    data['updatedAt'] = this.updatedAt;
    if (this.sender != null) {
      data['sender'] = this.sender?.toJson();
    }
    return data;
  }
}

class Sender {
  String? id;
  String? username;
  bool? isOnline;

  Sender({this.id, this.username, this.isOnline});

  Sender.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    isOnline = json['isOnline'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['username'] = this.username;
    data['isOnline'] = this.isOnline;
    return data;
  }
}

class Pagination {
  int? currentPage;
  int? pageSize;
  int? total;
  int? totalPages;

  Pagination({this.currentPage, this.pageSize, this.total, this.totalPages});

  Pagination.fromJson(Map<String, dynamic> json) {
    currentPage = json['currentPage'];
    pageSize = json['pageSize'];
    total = json['total'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['currentPage'] = this.currentPage;
    data['pageSize'] = this.pageSize;
    data['total'] = this.total;
    data['totalPages'] = this.totalPages;
    return data;
  }
}
