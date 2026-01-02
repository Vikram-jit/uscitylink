import 'package:chat_app/modules/home/models/pagination_model.dart';
import 'package:chat_app/modules/home/models/user_profile_model.dart';

class UserReponseModel {
  List<UserProfileModel>? users;
  PaginationModel? pagination;

  UserReponseModel({this.users, this.pagination});

  UserReponseModel.fromJson(Map<String, dynamic> json) {
    if (json['users'] != null) {
      users = <UserProfileModel>[];
      json['users'].forEach((v) {
        users!.add(new UserProfileModel.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new PaginationModel.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.users != null) {
      data['users'] = this.users!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}
