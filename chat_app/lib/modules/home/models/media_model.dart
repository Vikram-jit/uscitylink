import 'package:chat_app/modules/home/models/channel_model.dart';

class MediaModelResponse {
  ChannelModel? channel;
  List<MediaModel>? media;
  int? page;
  int? limit;
  int? totalItems;
  int? totalPages;

  MediaModelResponse({
    this.channel,
    this.media,
    this.page,
    this.limit,
    this.totalItems,
    this.totalPages,
  });

  MediaModelResponse.fromJson(Map<String, dynamic> json) {
    channel = json['channel'] != null
        ? new ChannelModel.fromJson(json['channel'])
        : null;
    if (json['media'] != null) {
      media = <MediaModel>[];
      json['media'].forEach((v) {
        media!.add(new MediaModel.fromJson(v));
      });
    }
    page = json['page'];
    limit = json['limit'];
    totalItems = json['totalItems'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.channel != null) {
      data['channel'] = this.channel!.toJson();
    }
    if (this.media != null) {
      data['media'] = this.media!.map((v) => v.toJson()).toList();
    }
    data['page'] = this.page;
    data['limit'] = this.limit;
    data['totalItems'] = this.totalItems;
    data['totalPages'] = this.totalPages;
    return data;
  }
}

class MediaModel {
  String? id;
  String? channelId;
  String? privateChatId;
  String? tempId;
  String? uploadSource;
  String? userProfileId;
  String? groupId;
  String? fileName;
  String? fileType;
  String? thumbnail;
  String? fileSize;
  String? mimeType;
  String? key;
  String? uploadType;
  String? createdAt;
  String? updatedAt;

  MediaModel({
    this.id,
    this.channelId,
    this.privateChatId,
    this.tempId,
    this.uploadSource,
    this.userProfileId,
    this.groupId,
    this.fileName,
    this.fileType,
    this.thumbnail,
    this.fileSize,
    this.mimeType,
    this.key,
    this.uploadType,
    this.createdAt,
    this.updatedAt,
  });

  MediaModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    channelId = json['channelId'];
    privateChatId = json['private_chat_id'];
    tempId = json['temp_id'];
    uploadSource = json['upload_source'];
    userProfileId = json['user_profile_id'];
    groupId = json['groupId'];
    fileName = json['file_name'];
    fileType = json['file_type'];
    thumbnail = json['thumbnail'];
    fileSize = json['file_size'];
    mimeType = json['mime_type'];
    key = json['key'];
    uploadType = json['upload_type'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['channelId'] = this.channelId;
    data['private_chat_id'] = this.privateChatId;
    data['temp_id'] = this.tempId;
    data['upload_source'] = this.uploadSource;
    data['user_profile_id'] = this.userProfileId;
    data['groupId'] = this.groupId;
    data['file_name'] = this.fileName;
    data['file_type'] = this.fileType;
    data['thumbnail'] = this.thumbnail;
    data['file_size'] = this.fileSize;
    data['mime_type'] = this.mimeType;
    data['key'] = this.key;
    data['upload_type'] = this.uploadType;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
