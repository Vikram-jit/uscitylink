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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
