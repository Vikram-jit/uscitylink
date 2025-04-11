import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/pagination_model.dart';

class MessageV2Model {
  List<MessageModel>? messages;
  PaginationModel? pagination;

  // Constructor with named parameters
  MessageV2Model({this.messages, this.pagination});

  // From JSON constructor
  MessageV2Model.fromJson(Map<String, dynamic> json) {
    if (json['messages'] != null) {
      messages =
          <MessageModel>[]; // Ensure messages is initialized as an empty list
      json['messages'].forEach((v) {
        messages!.add(MessageModel.fromJson(
            v)); // Use '!' for null-assertion, because we initialize 'messages'
      });
    }
    pagination = json['pagination'] != null
        ? PaginationModel.fromJson(json['pagination'])
        : null;
  }

  // To JSON method
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    if (messages != null) {
      data['messages'] = messages?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
