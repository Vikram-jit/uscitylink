import 'package:uscitylink/model/group_model.dart';
import 'package:uscitylink/model/sender_model.dart';

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
  SenderModel? sender;
  Group? group;
  String? type;
  String? thumbnail;
  String? driverPin;
  String? staffPin;
  String? url_upload_type;
  MessageModel? r_message;

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
      this.url,
      this.sender,
      this.group,
      this.type,
      this.thumbnail,
      this.r_message,
      this.driverPin,
      this.staffPin,
      this.url_upload_type});

  MessageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    url_upload_type = json['url_upload_type'];
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
    type = json['type'];
    thumbnail = json['thumbnail'];
    staffPin = json['staffPin'];
    driverPin = json['driverPin'];
    r_message = json['r_message'] != null
        ? MessageModel.fromJson(json['r_message'])
        : null;
    sender =
        json['sender'] != null ? SenderModel.fromJson(json['sender']) : null;
    group = json['group'] != null ? Group.fromJson(json['group']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['url_upload_type'] = url_upload_type;
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
    data['thumbnail'] = thumbnail;
    data['type'] = type;
    data['driverPin'] = driverPin;
    data['staffPin'] = staffPin;
    if (sender != null) {
      data['sender'] = sender?.toJson();
    }
    if (r_message != null) {
      data['r_message'] = r_message?.toJson();
    }
    if (group != null) {
      data['group'] = group?.toJson();
    }
    return data;
  }
}
