import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/staff/channel_chat_user_model.dart';

class UserMessageModel {
  UserProfile? userProfile;
  List<MessageModel>? messages;
  Pagination? pagination;

  UserMessageModel({this.userProfile, this.messages, this.pagination});

  UserMessageModel.fromJson(Map<String, dynamic> json) {
    userProfile = json['userProfile'] != null
        ? new UserProfile.fromJson(json['userProfile'])
        : null;
    if (json['messages'] != null) {
      messages = <MessageModel>[];
      json['messages'].forEach((v) {
        messages?.add(new MessageModel.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.userProfile != null) {
      data['userProfile'] = this.userProfile?.toJson();
    }
    if (this.messages != null) {
      data['messages'] = this.messages?.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination?.toJson();
    }
    return data;
  }
}

class Sender {
  String? id;
  String? username;
  bool? isOnline;

  Sender({this.id, this.username, this.isOnline});

  Sender.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    isOnline = json['isOnline'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['username'] = this.username;
    data['isOnline'] = this.isOnline;
    return data;
  }
}

class Pagination {
  int? currentPage;
  int? pageSize;
  int? total;
  int? totalPages;

  Pagination({this.currentPage, this.pageSize, this.total, this.totalPages});

  Pagination.fromJson(Map<String, dynamic> json) {
    currentPage = json['currentPage'];
    pageSize = json['pageSize'];
    total = json['total'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['currentPage'] = this.currentPage;
    data['pageSize'] = this.pageSize;
    data['total'] = this.total;
    data['totalPages'] = this.totalPages;
    return data;
  }
}
