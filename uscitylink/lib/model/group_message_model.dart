import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/truck_model.dart';

class GroupMessageModel {
  String? senderId;
  List<MessageModel>? messages;
  Pagination? pagination;

  // Constructor with named parameters
  GroupMessageModel({this.senderId, this.messages, this.pagination});

  // From JSON constructor
  GroupMessageModel.fromJson(Map<String, dynamic> json) {
    senderId = json['senderId'];
    if (json['messages'] != null) {
      messages =
          <MessageModel>[]; // Ensure messages is initialized as an empty list
      json['messages'].forEach((v) {
        messages!.add(MessageModel.fromJson(
            v)); // Use '!' for null-assertion, because we initialize 'messages'
      });
    }
    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;
  }

  // To JSON method
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['senderId'] = senderId;
    if (messages != null) {
      data['messages'] = messages?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
