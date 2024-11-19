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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
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
      this.updatedAt});

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
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['channelId'] = this.channelId;
    data['user_profile_id'] = this.userProfileId;
    // data['groupId'] = this.groupId;
    data['file_name'] = this.fileName;
    // data['file_type'] = this.fileType;
    data['file_size'] = this.fileSize;
    data['mime_type'] = this.mimeType;
    data['key'] = this.key;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
