import 'dart:convert';

import 'package:uscitylink/model/channel_model.dart';
import 'package:uscitylink/model/message_model.dart';

class UserChannelModel {
  String? id;
  String? userProfileId;
  String? channelId;
  String? createdAt;
  String? updatedAt;
  ChannelModel? channel;
  MessageModel? last_message;
  int? recieve_message_count;

  UserChannelModel(
      {required this.id,
      this.userProfileId,
      this.channelId,
      this.createdAt,
      this.updatedAt,
      this.channel,
      this.last_message,
      this.recieve_message_count});

  UserChannelModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userProfileId = json['userProfileId'];
    channelId = json['channelId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    recieve_message_count = json['recieve_message_count'];
    channel =
        json['Channel'] != null ? ChannelModel.fromJson(json['Channel']) : null;
    last_message = json['last_message'] != null
        ? MessageModel.fromJson(json['last_message'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['userProfileId'] = userProfileId;
    data['channelId'] = channelId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['recieve_message_count'] = recieve_message_count;
    if (channel != null) {
      data['Channel'] = channel?.toJson();
    }
    if (last_message != null) {
      data['last_message'] = last_message?.toJson();
    }
    return data;
  }

  void updateWithNewMessage(
    MessageModel message,
  ) {
    last_message = message;
  }
}
