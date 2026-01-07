import 'package:chat_app/models/group_model.dart';
import 'package:chat_app/modules/home/models/pagination_model.dart';
import 'package:chat_app/modules/home/models/user_model.dart';
import 'package:chat_app/modules/home/models/user_profile_model.dart';

class MessageResponseModel {
  UserProfileModel? userProfile;
  List<Messages>? messages;
  String? truckNumbers;
  PaginationModel? pagination;

  MessageResponseModel({
    this.userProfile,
    this.messages,
    this.truckNumbers,
    this.pagination,
  });

  MessageResponseModel.fromJson(Map<String, dynamic> json) {
    userProfile = json['userProfile'] != null
        ? new UserProfileModel.fromJson(json['userProfile'])
        : null;
    if (json['messages'] != null) {
      messages = <Messages>[];
      json['messages'].forEach((v) {
        messages!.add(new Messages.fromJson(v));
      });
    }
    truckNumbers = json['truckNumbers'];
    pagination = json['pagination'] != null
        ? new PaginationModel.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.userProfile != null) {
      data['userProfile'] = this.userProfile!.toJson();
    }
    if (this.messages != null) {
      data['messages'] = this.messages!.map((v) => v.toJson()).toList();
    }
    data['truckNumbers'] = this.truckNumbers;
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class Messages {
  String? id;
  String? channelId;
  String? tempId;
  String? userProfileId;
  String? privateChatId;
  String? groupId;
  String? body;
  String? messageDirection;
  String? deliveryStatus;
  String? messageTimestampUtc;
  String? senderId;
  String? url;
  String? thumbnail;
  bool? isRead;
  String? status;
  String? type;
  String? driverPin;
  String? staffPin;
  String? urlUploadType;
  String? replyMessageId;
  String? createdAt;
  String? updatedAt;
  Messages? rMessage;
  Sender? sender;
  GroupModel? group;

  Messages({
    this.id,
    this.channelId,
    this.tempId,
    this.userProfileId,
    this.privateChatId,
    this.groupId,
    this.body,
    this.messageDirection,
    this.deliveryStatus,
    this.messageTimestampUtc,
    this.senderId,
    this.url,
    this.thumbnail,
    this.isRead,
    this.status,
    this.type,
    this.driverPin,
    this.staffPin,
    this.urlUploadType,
    this.replyMessageId,
    this.createdAt,
    this.updatedAt,
    this.rMessage,
    this.sender,
    this.group,
  });

  Messages.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    channelId = json['channelId'];
    tempId = json['temp_id'];
    userProfileId = json['userProfileId'];
    privateChatId = json['private_chat_id'];
    groupId = json['groupId'];
    body = json['body'];
    messageDirection = json['messageDirection'];
    deliveryStatus = json['deliveryStatus'];
    messageTimestampUtc = json['messageTimestampUtc'];
    senderId = json['senderId'];
    url = json['url'];
    thumbnail = json['thumbnail'];
    isRead = json['isRead'];
    status = json['status'];
    type = json['type'];
    driverPin = json['driverPin'];
    staffPin = json['staffPin'];
    urlUploadType = json['url_upload_type'];
    replyMessageId = json['reply_message_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    rMessage = json['r_message'] != null
        ? Messages.fromJson(json['r_message'])
        : null;
    sender = json['sender'] != null ? Sender.fromJson(json['sender']) : null;
    group = json['group'] != null ? GroupModel.fromJson(json['group']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['channelId'] = this.channelId;
    data['temp_id'] = this.tempId;
    data['userProfileId'] = this.userProfileId;
    data['private_chat_id'] = this.privateChatId;
    data['groupId'] = this.groupId;
    data['body'] = this.body;
    data['messageDirection'] = this.messageDirection;
    data['deliveryStatus'] = this.deliveryStatus;
    data['messageTimestampUtc'] = this.messageTimestampUtc;
    data['senderId'] = this.senderId;
    data['url'] = this.url;
    data['thumbnail'] = this.thumbnail;
    data['isRead'] = this.isRead;
    data['status'] = this.status;
    data['type'] = this.type;
    data['driverPin'] = this.driverPin;
    data['staffPin'] = this.staffPin;
    data['url_upload_type'] = this.urlUploadType;
    data['reply_message_id'] = this.replyMessageId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    if (this.sender != null) {
      data['sender'] = this.sender!.toJson();
    }
    if (this.rMessage != null) {
      data['rMessage'] = this.rMessage!.toJson();
    }
    if (this.group != null) {
      data['group'] = this.group!.toJson();
    }

    return data;
  }
}

class Sender {
  String? id;
  String? username;
  bool? isOnline;
  UserModel? user;

  Sender({this.id, this.username, this.isOnline, this.user});

  Sender.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    isOnline = json['isOnline'];
    user = json['user'] != null ? new UserModel.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['username'] = this.username;
    data['isOnline'] = this.isOnline;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    return data;
  }
}
