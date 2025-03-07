class MediaModel {
  Channel? channel;
  List<Media>? media; // This should be nullable
  int? page;
  int? limit;
  int? totalItems;
  int? totalPages;

  MediaModel({
    this.channel,
    this.media,
    this.page,
    this.limit,
    this.totalItems,
    this.totalPages,
  });

  MediaModel.fromJson(Map<String, dynamic> json) {
    // If 'channel' exists in JSON, map it to a Channel object
    channel =
        json['channel'] != null ? Channel.fromJson(json['channel']) : null;

    // Initialize the 'media' list using List<Media>.from or null if 'media' is not provided
    if (json['media'] != null) {
      media = List<Media>.from(json['media'].map((v) => Media.fromJson(v)));
    }

    // Populate other fields
    page = json['page'];
    limit = json['limit'];
    totalItems = json['totalItems'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (channel != null) {
      data['channel'] = channel?.toJson();
    }
    if (media != null) {
      data['media'] = media?.map((v) => v.toJson()).toList();
    }
    data['page'] = page;
    data['limit'] = limit;
    data['totalItems'] = totalItems;
    data['totalPages'] = totalPages;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}

class Media {
  String? id;
  String? channelId;
  String? userProfileId;
  // String? groupId;
  String? fileName;
  // String? fileType;
  String? fileSize;
  String? mimeType;
  String? key;
  String? createdAt;
  String? updatedAt;
  String? thumbnail;

  Media(
      {this.id,
      this.channelId,
      this.userProfileId,
      // this.groupId,
      this.fileName,
      // this.fileType,
      this.fileSize,
      this.mimeType,
      this.key,
      this.createdAt,
      this.updatedAt,
      this.thumbnail});

  Media.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    channelId = json['channelId'];
    userProfileId = json['user_profile_id'];
    // groupId = json['groupId'];
    fileName = json['file_name'];
    // fileType = json['file_type'];
    fileSize = json['file_size'];
    mimeType = json['mime_type'];
    key = json['key'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    thumbnail = json['thumbnail'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['channelId'] = channelId;
    data['user_profile_id'] = userProfileId;
    // data['groupId'] = this.groupId;
    data['file_name'] = fileName;
    // data['file_type'] = this.fileType;
    data['file_size'] = fileSize;
    data['mime_type'] = mimeType;
    data['key'] = key;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['thumbnail'] = thumbnail;
    return data;
  }
}
