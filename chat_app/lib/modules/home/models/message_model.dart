class MessageModel {
  String? id;
  String? channelId;
  String? tempId;
  String? userProfileId;
  String? privateChatId;
  String? groupId;
  String? body;
  String? messageDirection;
  String? deliveryStatus;
  String? messageTimestampUtc;
  String? senderId;
  String? url;
  String? thumbnail;
  bool? isRead;
  String? status;
  String? type;
  String? driverPin;
  String? staffPin;
  String? urlUploadType;
  String? replyMessageId;
  String? createdAt;
  String? updatedAt;

  MessageModel({
    this.id,
    this.channelId,
    this.tempId,
    this.userProfileId,
    this.privateChatId,
    this.groupId,
    this.body,
    this.messageDirection,
    this.deliveryStatus,
    this.messageTimestampUtc,
    this.senderId,
    this.url,
    this.thumbnail,
    this.isRead,
    this.status,
    this.type,
    this.driverPin,
    this.staffPin,
    this.urlUploadType,
    this.replyMessageId,
    this.createdAt,
    this.updatedAt,
  });

  MessageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    channelId = json['channelId'];
    tempId = json['temp_id'];
    userProfileId = json['userProfileId'];
    privateChatId = json['private_chat_id'];
    groupId = json['groupId'];
    body = json['body'];
    messageDirection = json['messageDirection'];
    deliveryStatus = json['deliveryStatus'];
    messageTimestampUtc = json['messageTimestampUtc'];
    senderId = json['senderId'];
    url = json['url'];
    thumbnail = json['thumbnail'];
    isRead = json['isRead'];
    status = json['status'];
    type = json['type'];
    driverPin = json['driverPin'];
    staffPin = json['staffPin'];
    urlUploadType = json['url_upload_type'];
    replyMessageId = json['reply_message_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['channelId'] = this.channelId;
    data['temp_id'] = this.tempId;
    data['userProfileId'] = this.userProfileId;
    data['private_chat_id'] = this.privateChatId;
    data['groupId'] = this.groupId;
    data['body'] = this.body;
    data['messageDirection'] = this.messageDirection;
    data['deliveryStatus'] = this.deliveryStatus;
    data['messageTimestampUtc'] = this.messageTimestampUtc;
    data['senderId'] = this.senderId;
    data['url'] = this.url;
    data['thumbnail'] = this.thumbnail;
    data['isRead'] = this.isRead;
    data['status'] = this.status;
    data['type'] = this.type;
    data['driverPin'] = this.driverPin;
    data['staffPin'] = this.staffPin;
    data['url_upload_type'] = this.urlUploadType;
    data['reply_message_id'] = this.replyMessageId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
