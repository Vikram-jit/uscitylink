import 'package:uscitylink/model/message_model.dart';

class ChannelChatUserModel {
  String? id;
  String? name;
  String? description;
  String? createdAt;
  String? updatedAt;
  List<UserChannels>? userChannels;
  Pagination? pagination;

  ChannelChatUserModel(
      {this.id,
      this.name,
      this.description,
      this.createdAt,
      this.updatedAt,
      this.userChannels,
      this.pagination});

  ChannelChatUserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    if (json['user_channels'] != null) {
      userChannels = <UserChannels>[];
      json['user_channels'].forEach((v) {
        userChannels?.add(new UserChannels.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    if (this.userChannels != null) {
      data['user_channels'] =
          this.userChannels?.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination?.toJson();
    }
    return data;
  }
}

class UserChannels {
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
  LastMessage? lastMessage;
  int? unreadCount;
  UserChannels(
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
      this.userProfile,
      this.lastMessage,
      this.unreadCount});

  UserChannels.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userProfileId = json['userProfileId'];
    unreadCount = json['unreadCount'];
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
    lastMessage = json['last_message'] != null
        ? new LastMessage.fromJson(json['last_message'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['unreadCount'] = this.unreadCount;
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
    if (this.lastMessage != null) {
      data['last_message'] = this.lastMessage?.toJson();
    }
    return data;
  }

  void updateWithNewMessage(
    LastMessage message,
  ) {
    lastMessage = message;
  }
}

class UserProfile {
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
  String? channelId;
  String? createdAt;
  String? updatedAt;
  User? user;

  UserProfile(
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
      this.channelId,
      this.createdAt,
      this.updatedAt,
      this.user});

  UserProfile.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    username = json['username'];
    profilePic = json['profile_pic'];
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

class LastMessage {
  String? id;
  String? channelId;
  String? userProfileId;
  String? groupId;
  String? body;
  String? messageDirection;
  String? deliveryStatus;
  String? messageTimestampUtc;
  String? senderId;
  String? url;
  bool? isRead;
  String? status;
  String? type;
  String? createdAt;
  String? updatedAt;

  LastMessage(
      {this.id,
      this.channelId,
      this.userProfileId,
      this.groupId,
      this.body,
      this.messageDirection,
      this.deliveryStatus,
      this.messageTimestampUtc,
      this.senderId,
      this.url,
      this.isRead,
      this.status,
      this.type,
      this.createdAt,
      this.updatedAt});

  LastMessage.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    channelId = json['channelId'];
    userProfileId = json['userProfileId'];
    groupId = json['groupId'];
    body = json['body'];
    messageDirection = json['messageDirection'];
    deliveryStatus = json['deliveryStatus'];
    messageTimestampUtc = json['messageTimestampUtc'];
    senderId = json['senderId'];
    url = json['url'];
    isRead = json['isRead'];
    status = json['status'];
    type = json['type'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['channelId'] = this.channelId;
    data['userProfileId'] = this.userProfileId;
    data['groupId'] = this.groupId;
    data['body'] = this.body;
    data['messageDirection'] = this.messageDirection;
    data['deliveryStatus'] = this.deliveryStatus;
    data['messageTimestampUtc'] = this.messageTimestampUtc;
    data['senderId'] = this.senderId;
    data['url'] = this.url;
    data['isRead'] = this.isRead;
    data['status'] = this.status;
    data['type'] = this.type;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
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
