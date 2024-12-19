import 'package:uscitylink/model/group_members_model.dart';
import 'package:uscitylink/model/message_model.dart';

class GroupSingleModel {
  Group? group;
  List<GroupMembers>? groupMembers;

  GroupSingleModel({this.group, this.groupMembers});

  GroupSingleModel.fromJson(Map<String, dynamic> json) {
    group = json['group'] != null ? new Group.fromJson(json['group']) : null;
    if (json['groupMembers'] != null) {
      groupMembers = <GroupMembers>[];
      json['groupMembers'].forEach((v) {
        groupMembers!.add(new GroupMembers.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.group != null) {
      data['group'] = this.group!.toJson();
    }
    if (this.groupMembers != null) {
      data['groupMembers'] = this.groupMembers!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class GroupModel {
  String? id;
  String? groupId;
  String? userProfileId;
  String? status;
  String? createdAt;
  String? updatedAt;
  MessageModel? last_message;
  int? message_count;
  Group? group;

  GroupModel(
      {this.id,
      this.groupId,
      this.userProfileId,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.group,
      this.last_message,
      this.message_count});

  GroupModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    groupId = json['groupId'];
    userProfileId = json['userProfileId'];
    status = json['status'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    message_count = json['message_count'];
    last_message = json['last_message'] != null
        ? MessageModel.fromJson(json['last_message'])
        : null;
    group = json['Group'] != null ? new Group.fromJson(json['Group']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['groupId'] = this.groupId;
    data['userProfileId'] = this.userProfileId;
    data['status'] = this.status;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['message_count'] = this.message_count;
    if (this.group != null) {
      data['Group'] = this.group?.toJson();
    }
    if (last_message != null) {
      data['last_message'] = last_message?.toJson();
    }
    return data;
  }

  void updateWithNewMessage(MessageModel message) {
    last_message = message;
    message_count = (message_count ?? 0) + 1;
  }
}

class Group {
  String? id;
  String? name;
  String? description;
  String? type;
  String? createdAt;
  String? updatedAt;
  GroupChannel? groupChannel;
  Group(
      {this.id,
      this.name,
      this.description,
      this.type,
      this.createdAt,
      this.updatedAt,
      this.groupChannel});

  Group.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    type = json['type'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    groupChannel = json['group_channel'] != null
        ? GroupChannel.fromJson(json['group_channel'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
    data['type'] = this.type;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    if (groupChannel != null) {
      data['group_channel'] = this.groupChannel?.toJson();
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

  GroupChannel(
      {this.id, this.groupId, this.channelId, this.createdAt, this.updatedAt});

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
