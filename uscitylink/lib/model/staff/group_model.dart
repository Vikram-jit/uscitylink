class GroupModel {
  List<Group>? data;
  Channel? channel;
  Pagination? pagination;

  GroupModel({this.data, this.channel, this.pagination});

  GroupModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Group>[];
      json['data'].forEach((v) {
        data?.add(new Group.fromJson(v));
      });
    }
    channel =
        json['channel'] != null ? new Channel.fromJson(json['channel']) : null;
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data?.map((v) => v.toJson()).toList();
    }
    if (this.channel != null) {
      data['channel'] = this.channel?.toJson();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination?.toJson();
    }
    return data;
  }
}

class Group {
  String? id;
  String? name;
  String? description;
  String? type;
  String? lastMessageId;
  int? messageCount;
  String? createdAt;
  String? updatedAt;
  GroupChannel? groupChannel;
  LastMessage? lastMessage;

  Group(
      {this.id,
      this.name,
      this.description,
      this.type,
      this.lastMessageId,
      this.messageCount,
      this.createdAt,
      this.updatedAt,
      this.groupChannel,
      this.lastMessage});

  Group.fromJson(Map<String, dynamic> json) {
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
        ? new LastMessage.fromJson(json['last_message'])
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
      data['group_channel'] = this.groupChannel?.toJson();
    }
    if (this.lastMessage != null) {
      data['last_message'] = this.lastMessage?.toJson();
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

class Channel {
  String? id;
  String? name;
  String? description;
  String? createdAt;
  String? updatedAt;

  Channel(
      {this.id, this.name, this.description, this.createdAt, this.updatedAt});

  Channel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
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
