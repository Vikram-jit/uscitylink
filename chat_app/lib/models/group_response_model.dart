import 'package:chat_app/modules/home/models/channel_model.dart';
import 'package:chat_app/modules/home/models/message_model.dart';
import 'package:chat_app/modules/home/models/pagination_model.dart';

class GroupResponseModel {
  List<GroupModel>? data;
  ChannelModel? channel;
  PaginationModel? pagination;

  GroupResponseModel({this.data, this.channel, this.pagination});

  GroupResponseModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <GroupModel>[];
      json['data'].forEach((v) {
        data!.add(GroupModel.fromJson(v));
      });
    }
    channel = json['channel'] != null
        ? ChannelModel.fromJson(json['channel'])
        : null;
    pagination = json['pagination'] != null
        ? PaginationModel.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (channel != null) {
      data['channel'] = channel!.toJson();
    }
    if (pagination != null) {
      data['pagination'] = pagination!.toJson();
    }
    return data;
  }
}

class GroupModel {
  String? id;
  String? name;
  String? description;
  String? type;
  String? lastMessageId;
  int? messageCount;
  String? createdAt;
  String? updatedAt;
  GroupChannel? groupChannel;
  MessageModel? lastMessage;

  GroupModel({
    this.id,
    this.name,
    this.description,
    this.type,
    this.lastMessageId,
    this.messageCount,
    this.createdAt,
    this.updatedAt,
    this.groupChannel,
    this.lastMessage,
  });

  GroupModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    type = json['type'];
    lastMessageId = json['last_message_id'];
    messageCount = json['message_count'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    groupChannel = json['group_channel'] != null
        ? new GroupChannel.fromJson(json['group_channel'])
        : null;
    lastMessage = json['last_message'] != null
        ? new MessageModel.fromJson(json['last_message'])
        : null;
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
    if (this.groupChannel != null) {
      data['group_channel'] = this.groupChannel!.toJson();
    }
    if (this.lastMessage != null) {
      data['last_message'] = this.lastMessage!.toJson();
    }
    return data;
  }
}

class GroupChannel {
  String? id;
  String? groupId;
  String? channelId;
  String? createdAt;
  String? updatedAt;

  GroupChannel({
    this.id,
    this.groupId,
    this.channelId,
    this.createdAt,
    this.updatedAt,
  });

  GroupChannel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    groupId = json['groupId'];
    channelId = json['channelId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['groupId'] = this.groupId;
    data['channelId'] = this.channelId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
