import 'package:uscitylink/model/message_model.dart';

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
  Sender? userProfile;

  GroupMembers(
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
        ? Sender.fromJson(json['UserProfile'])
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
    data['UserProfile'] = this.userProfile?.toJson();
    return data;
  }
}

class EventGroupMemberModel {
  String? event;
  GroupMembers? member;

  EventGroupMemberModel({this.event, this.member});

  EventGroupMemberModel.fromJson(Map<String, dynamic> json) {
    member = json['member'] != null
        ? new GroupMembers.fromJson(json['member'])
        : null;
    event = json['event'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.member != null) {
      data['member'] = this.member!.toJson();
    }
    data['event'] = this.event;
    return data;
  }
}
