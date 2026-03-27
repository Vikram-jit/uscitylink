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
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['channelId'] = channelId;
    data['temp_id'] = tempId;
    data['userProfileId'] = userProfileId;
    data['private_chat_id'] = privateChatId;
    data['groupId'] = groupId;
    data['body'] = body;
    data['messageDirection'] = messageDirection;
    data['deliveryStatus'] = deliveryStatus;
    data['messageTimestampUtc'] = messageTimestampUtc;
    data['senderId'] = senderId;
    data['url'] = url;
    data['thumbnail'] = thumbnail;
    data['isRead'] = isRead;
    data['status'] = status;
    data['type'] = type;
    data['driverPin'] = driverPin;
    data['staffPin'] = staffPin;
    data['url_upload_type'] = urlUploadType;
    data['reply_message_id'] = replyMessageId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }

  /// Extract file extension
  String get extLower {
    if (url == null) return '';
    return url!.split('.').last.toLowerCase();
  }

  bool get isImage => ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(extLower);

  bool get isVideo => ['mp4', 'mov', 'mkv', 'webm'].contains(extLower);

  bool get isAudio => ['mp3', 'wav', 'm4a', 'aac'].contains(extLower);

  bool get isPdf => extLower == 'pdf';
}
