class ChannelModel {
  String? id;
  String? name;
  String? description;
  String? createdAt;
  String? updatedAt;
  bool? isActive;

  ChannelModel(
      {this.id,
      this.name,
      this.description,
      this.createdAt,
      this.updatedAt,
      this.isActive});

  ChannelModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    isActive = json['isActive'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['isActive'] = this.isActive;
    return data;
  }
}
