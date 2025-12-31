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
  List<GroupUsers>? groupUsers;

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
    this.groupUsers,
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
    if (json['group_users'] != null) {
      groupUsers = <GroupUsers>[];
      json['group_users'].forEach((v) {
        groupUsers!.add(new GroupUsers.fromJson(v));
      });
    }
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
    if (this.groupUsers != null) {
      data['group_users'] = this.groupUsers!.map((v) => v.toJson()).toList();
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

class GroupUsers {
  String? id;
  String? groupId;
  String? userProfileId;
  String? status;
  Null? lastMessageId;
  int? messageCount;
  String? lastMessageUtc;
  String? createdAt;
  String? updatedAt;

  GroupUsers({
    this.id,
    this.groupId,
    this.userProfileId,
    this.status,
    this.lastMessageId,
    this.messageCount,
    this.lastMessageUtc,
    this.createdAt,
    this.updatedAt,
  });

  GroupUsers.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    groupId = json['groupId'];
    userProfileId = json['userProfileId'];
    status = json['status'];
    lastMessageId = json['last_message_id'];
    messageCount = json['message_count'];
    lastMessageUtc = json['last_message_utc'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
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
    return data;
  }
}
