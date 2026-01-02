import 'package:chat_app/modules/home/models/message_model.dart';
import 'package:chat_app/modules/home/models/pagination_model.dart';
import 'package:chat_app/modules/home/models/user_profile_model.dart';

class ChannelMemmberModel {
  String? id;
  String? name;
  String? description;
  String? createdAt;
  String? updatedAt;
  List<UserChannels>? userChannels;
  PaginationModel? pagination;

  ChannelMemmberModel({
    this.id,
    this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.userChannels,
    this.pagination,
  });

  ChannelMemmberModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    if (json['user_channels'] != null) {
      userChannels = <UserChannels>[];
      json['user_channels'].forEach((v) {
        userChannels!.add(new UserChannels.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new PaginationModel.fromJson(json['pagination'])
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
      data['user_channels'] = this.userChannels!
          .map((v) => v.toJson())
          .toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
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
  UserProfileModel? userProfile;
  MessageModel? lastMessage;
  int? unreadCount;
  String? assginTrucks;

  UserChannels({
    this.id,
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
    this.unreadCount,
    this.assginTrucks,
  });

  UserChannels.fromJson(Map<String, dynamic> json) {
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
        ? new UserProfileModel.fromJson(json['UserProfile'])
        : null;
    lastMessage = json['last_message'] != null
        ? new MessageModel.fromJson(json['last_message'])
        : null;
    unreadCount = json['unreadCount'];
    assginTrucks = json['assginTrucks'];
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
      data['UserProfile'] = this.userProfile!.toJson();
    }
    if (this.lastMessage != null) {
      data['last_message'] = this.lastMessage!.toJson();
    }
    data['unreadCount'] = this.unreadCount;
    data['assginTrucks'] = this.assginTrucks;
    return data;
  }
}
