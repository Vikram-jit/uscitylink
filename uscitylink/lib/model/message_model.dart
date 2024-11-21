class MessageModel {
  String? id;
  String? channelId;
  String? userProfileId;
  String? groupId;
  String? body;
  String? messageDirection;
  String? deliveryStatus;
  String? messageTimestampUtc;
  String? senderId;
  bool? isRead;
  String? status;
  String? url;
  String? createdAt;
  String? updatedAt;

  MessageModel(
      {this.id,
      this.channelId,
      this.userProfileId,
      this.groupId,
      this.body,
      this.messageDirection,
      this.deliveryStatus,
      this.messageTimestampUtc,
      this.senderId,
      this.isRead,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.url});

  MessageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    channelId = json['channelId'];
    userProfileId = json['userProfileId'];
    groupId = json['groupId'];
    body = json['body'];
    messageDirection = json['messageDirection'];
    deliveryStatus = json['deliveryStatus'];
    messageTimestampUtc = json['messageTimestampUtc'];
    senderId = json['senderId'];
    isRead = json['isRead'];
    status = json['status'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['channelId'] = channelId;
    data['userProfileId'] = userProfileId;
    data['groupId'] = groupId;
    data['body'] = body;
    data['messageDirection'] = messageDirection;
    data['deliveryStatus'] = deliveryStatus;
    data['messageTimestampUtc'] = messageTimestampUtc;
    data['senderId'] = senderId;
    data['isRead'] = isRead;
    data['status'] = status;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['url'] = url;
    return data;
  }
}
