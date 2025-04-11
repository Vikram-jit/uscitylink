import 'package:uscitylink/model/staff/channel_chat_user_model.dart';
import 'package:uscitylink/model/user_model.dart';

class SenderModel {
  String? id;
  String? username;
  bool? isOnline;
  UserModel? user;
  SenderModel({this.id, this.username, this.isOnline, this.user});

  SenderModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    isOnline = json['isOnline'];
    user = json['user'] != null ? new UserModel.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['username'] = username;
    data['isOnline'] = isOnline;
    if (this.user != null) {
      data['user'] = this.user?.toJson();
    }
    return data;
  }
}
