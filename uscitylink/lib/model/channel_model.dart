class ChannelModel {
  String? id;
  String? name;
  String? description;
  String? createdAt;
  String? updatedAt;

  ChannelModel(
      {this.id, this.name, this.description, this.createdAt, this.updatedAt});

  ChannelModel.fromJson(Map<String, dynamic> json) {
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

class CountModel {
  int? total;
  int? channel;
  int? group;

  CountModel({this.total, this.channel, this.group});

  CountModel.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    channel = json['channel'];
    group = json['group'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['group'] = group;
    data['channel'] = channel;
    data['total'] = total;
    return data;
  }
}
