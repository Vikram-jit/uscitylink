import 'package:uscitylink/model/channel_model.dart';

class UserChannelModel {
  String? id;
  String? userProfileId;
  String? channelId;
  String? createdAt;
  String? updatedAt;
  ChannelModel? channel;

  UserChannelModel(
      {required this.id,
      this.userProfileId,
      this.channelId,
      this.createdAt,
      this.updatedAt,
      this.channel});

  UserChannelModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userProfileId = json['userProfileId'];
    channelId = json['channelId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    channel =
        json['Channel'] != null ? ChannelModel.fromJson(json['Channel']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['userProfileId'] = this.userProfileId;
    data['channelId'] = this.channelId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    if (this.channel != null) {
      data['Channel'] = this?.channel?.toJson();
    }
    return data;
  }
}
