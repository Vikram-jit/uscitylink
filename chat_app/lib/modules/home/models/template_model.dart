import 'package:chat_app/modules/home/models/pagination_model.dart';

class TemplateModel {
  List<Template>? data;
  PaginationModel? pagination;

  TemplateModel({this.data, this.pagination});

  TemplateModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Template>[];
      json['data'].forEach((v) {
        data!.add(new Template.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new PaginationModel.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class Template {
  String? id;
  String? channelId;
  String? userProfileId;
  String? body;
  String? name;
  String? url;
  String? createdAt;
  String? updatedAt;

  Template({
    this.id,
    this.channelId,
    this.userProfileId,
    this.body,
    this.name,
    this.url,
    this.createdAt,
    this.updatedAt,
  });

  Template.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    channelId = json['channelId'];
    userProfileId = json['userProfileId'];
    body = json['body'];
    name = json['name'];
    url = json['url'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['channelId'] = this.channelId;
    data['userProfileId'] = this.userProfileId;
    data['body'] = this.body;
    data['name'] = this.name;
    data['url'] = this.url;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
