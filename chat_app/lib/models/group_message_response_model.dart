import 'package:chat_app/models/group_response_model.dart';
import 'package:chat_app/models/message_response_model.dart';
import 'package:chat_app/modules/home/models/pagination_model.dart';
import 'package:chat_app/modules/home/models/user_profile_model.dart';

class GroupMessageResponseModel {
  String? senderId;
  GroupModel? group;
  List<GroupMembers>? members;
  List<Messages>? messages;
  PaginationModel? pagination;

  GroupMessageResponseModel({
    this.senderId,
    this.group,
    this.members,
    this.messages,
    this.pagination,
  });

  GroupMessageResponseModel.fromJson(Map<String, dynamic> json) {
    senderId = json['senderId'];
    group = json['group'] != null
        ? new GroupModel.fromJson(json['group'])
        : null;
    if (json['members'] != null) {
      members = <GroupMembers>[];
      json['members'].forEach((v) {
        members!.add(new GroupMembers.fromJson(v));
      });
    }
    if (json['messages'] != null) {
      messages = <Messages>[];
      json['messages'].forEach((v) {
        messages!.add(new Messages.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new PaginationModel.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['senderId'] = this.senderId;
    if (this.group != null) {
      data['group'] = this.group!.toJson();
    }
    if (this.members != null) {
      data['members'] = this.members!.map((v) => v.toJson()).toList();
    }
    if (this.messages != null) {
      data['messages'] = this.messages!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class GroupMembers {
  String? id;
  String? groupId;
  String? userProfileId;
  String? status;
  String? lastMessageId;
  int? messageCount;
  String? lastMessageUtc;
  String? createdAt;
  String? updatedAt;
  UserProfileModel? userProfile;

  GroupMembers({
    this.id,
    this.groupId,
    this.userProfileId,
    this.status,
    this.lastMessageId,
    this.messageCount,
    this.lastMessageUtc,
    this.createdAt,
    this.updatedAt,
    this.userProfile,
  });

  GroupMembers.fromJson(Map<String, dynamic> json) {
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
        ? new UserProfileModel.fromJson(json['UserProfile'])
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
      data['UserProfile'] = this.userProfile!.toJson();
    }
    return data;
  }
}
