import 'dart:ffi';

import 'package:uscitylink/model/group_model.dart';
import 'package:uscitylink/model/staff/channel_chat_user_model.dart';

class MessageModel {
  String? id;
  String? channelId;
  String? userProfileId;
  String? groupId;
  String? body;
  String? messageDirection;
  String? deliveryStatus;
  String? messageTimestampUtc;
  String? senderId;
  bool? isRead;
  String? status;
  String? url;
  String? createdAt;
  String? updatedAt;
  Sender? sender;
  Group? group;
  String? type;
  String? thumbnail;
  String? driverPin;
  String? staffPin;
  MessageModel? r_message;
  MessageModel(
      {this.id,
      this.channelId,
      this.userProfileId,
      this.groupId,
      this.body,
      this.messageDirection,
      this.deliveryStatus,
      this.messageTimestampUtc,
      this.senderId,
      this.isRead,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.url,
      this.sender,
      this.group,
      this.type,
      this.thumbnail,
      this.r_message,
      this.driverPin,
      this.staffPin});

  MessageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    channelId = json['channelId'];
    userProfileId = json['userProfileId'];
    groupId = json['groupId'];
    body = json['body'];
    messageDirection = json['messageDirection'];
    deliveryStatus = json['deliveryStatus'];
    messageTimestampUtc = json['messageTimestampUtc'];
    senderId = json['senderId'];
    isRead = json['isRead'];
    status = json['status'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    url = json['url'];
    type = json['type'];
    thumbnail = json['thumbnail'];
    staffPin = json['staffPin'];
    driverPin = json['driverPin'];
    r_message = json['r_message'] != null
        ? MessageModel.fromJson(json['r_message'])
        : null;
    sender = json['sender'] != null ? Sender.fromJson(json['sender']) : null;
    group = json['group'] != null ? Group.fromJson(json['group']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['channelId'] = channelId;
    data['userProfileId'] = userProfileId;
    data['groupId'] = groupId;
    data['body'] = body;
    data['messageDirection'] = messageDirection;
    data['deliveryStatus'] = deliveryStatus;
    data['messageTimestampUtc'] = messageTimestampUtc;
    data['senderId'] = senderId;
    data['isRead'] = isRead;
    data['status'] = status;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['url'] = url;
    data['thumbnail'] = thumbnail;
    data['type'] = type;
    data['driverPin'] = driverPin;
    data['staffPin'] = staffPin;
    if (sender != null) {
      data['sender'] = sender?.toJson();
    }
    if (r_message != null) {
      data['r_message'] = r_message?.toJson();
    }
    if (group != null) {
      data['group'] = group?.toJson();
    }
    return data;
  }
}

class Sender {
  String? id;
  String? username;
  bool? isOnline;
  User? user;
  Sender({this.id, this.username, this.isOnline, this.user});

  Sender.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    isOnline = json['isOnline'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['username'] = username;
    data['isOnline'] = isOnline;
    if (this.user != null) {
      data['user'] = this.user?.toJson();
    }
    return data;
  }
}
