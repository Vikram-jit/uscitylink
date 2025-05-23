import 'package:uscitylink/model/sender_model.dart';

class DashboardModel {
  Channel? channel;
  String? trucks;
  int? channelCount;
  int? messageCount;
  int? groupCount;
  int? truckCount;
  int? trailerCount;
  double? totalAmount;
  bool? isDocumentExpired;
  List<LatestMessage>? latestMessage;
  List<LatestGroupMessage>? latestGroupMessage;

  DashboardModel(
      {this.trucks,
      this.channelCount,
      this.messageCount,
      this.groupCount,
      this.truckCount,
      this.trailerCount,
      this.latestMessage,
      this.latestGroupMessage,
      this.channel,
      this.totalAmount,
      this.isDocumentExpired});

  DashboardModel.fromJson(Map<String, dynamic> json) {
    channelCount = json['channelCount'];
    messageCount = json['messageCount'];
    groupCount = json['groupCount'];
    truckCount = json['truckCount'];
    totalAmount = (json['totalAmount'] as num?)?.toDouble();
    isDocumentExpired = json['isDocumentExpired'];
    trucks = json['trucks'];
    channel =
        json['channel'] != null ? new Channel.fromJson(json['channel']) : null;
    trailerCount = json['trailerCount'];
    if (json['latestMessage'] != null) {
      latestMessage = <LatestMessage>[];
      json['latestMessage'].forEach((v) {
        latestMessage!.add(new LatestMessage.fromJson(v));
      });
    }
    if (json['latestGroupMessage'] != null) {
      latestGroupMessage = <LatestGroupMessage>[];
      json['latestGroupMessage'].forEach((v) {
        latestGroupMessage!.add(LatestGroupMessage.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    if (this.channel != null) {
      data['channel'] = this.channel!.toJson();
    }
    data['channelCount'] = this.channelCount;
    data['trucks'] = trucks;
    data['totalAmount'] =
        (this.totalAmount is num) ? this.totalAmount?.toDouble() : 0.0;
    data['messageCount'] = this.messageCount;
    data['groupCount'] = this.groupCount;
    data['truckCount'] = this.truckCount;
    data['isDocumentExpired'] = this.isDocumentExpired;
    data['trailerCount'] = this.trailerCount;
    if (this.latestMessage != null) {
      data['latestMessage'] = latestMessage?.map((v) => v.toJson()).toList();
    }
    if (latestGroupMessage != null) {
      data['latestGroupMessage'] =
          latestGroupMessage?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class LatestMessage {
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
  SenderModel? sender;
  Channel? channel;

  LatestMessage(
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
      this.updatedAt,
      this.sender,
      this.channel});

  LatestMessage.fromJson(Map<String, dynamic> json) {
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
    sender = json['sender'] != null
        ? new SenderModel.fromJson(json['sender'])
        : null;
    channel =
        json['channel'] != null ? new Channel.fromJson(json['channel']) : null;
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
    if (this.sender != null) {
      data['sender'] = this.sender!.toJson();
    }
    if (this.channel != null) {
      data['channel'] = this.channel!.toJson();
    }
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

class LatestGroupMessage {
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
  SenderModel? sender;
  Channel? channel;
  GroupDashboard? group;

  LatestGroupMessage(
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
      this.updatedAt,
      this.sender,
      this.channel,
      this.group});

  LatestGroupMessage.fromJson(Map<String, dynamic> json) {
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
    sender = json['sender'] != null
        ? new SenderModel.fromJson(json['sender'])
        : null;
    channel =
        json['channel'] != null ? new Channel.fromJson(json['channel']) : null;
    group = json['group'] != null
        ? new GroupDashboard.fromJson(json['group'])
        : null;
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
    if (this.sender != null) {
      data['sender'] = this.sender!.toJson();
    }
    if (this.channel != null) {
      data['channel'] = this.channel!.toJson();
    }
    if (this.group != null) {
      data['group'] = this.group!.toJson();
    }
    return data;
  }
}

class GroupDashboard {
  String? id;
  String? name;
  String? description;
  String? type;
  String? lastMessageId;
  int? messageCount;
  String? createdAt;
  String? updatedAt;

  GroupDashboard(
      {this.id,
      this.name,
      this.description,
      this.type,
      this.lastMessageId,
      this.messageCount,
      this.createdAt,
      this.updatedAt});

  GroupDashboard.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    type = json['type'];
    lastMessageId = json['last_message_id'];
    messageCount = json['message_count'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
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
    return data;
  }
}
