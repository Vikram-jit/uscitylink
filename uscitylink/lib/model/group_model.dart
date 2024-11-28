class GroupModel {
  String? id;
  String? groupId;
  String? userProfileId;
  String? status;
  String? createdAt;
  String? updatedAt;
  Group? group;

  GroupModel(
      {this.id,
      this.groupId,
      this.userProfileId,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.group});

  GroupModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    groupId = json['groupId'];
    userProfileId = json['userProfileId'];
    status = json['status'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
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
    if (this.group != null) {
      data['Group'] = this.group?.toJson();
    }
    return data;
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
        ? new GroupChannel.fromJson(json['group_channel'])
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
    if (this.groupChannel != null) {
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
