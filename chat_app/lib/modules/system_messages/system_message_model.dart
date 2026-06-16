import 'package:chat_app/modules/home/models/pagination_model.dart';
import 'package:chat_app/modules/home/models/user_profile_model.dart';

class SystemMessageResponse {
  final List<SystemMessage> messages;
  final PaginationModel pagination;

  SystemMessageResponse({required this.messages, required this.pagination});

  factory SystemMessageResponse.fromJson(Map<String, dynamic> json) {
    return SystemMessageResponse(
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((e) => SystemMessage.fromJson(e))
          .toList(),
      pagination: PaginationModel.fromJson(json['pagination'] ?? {}),
    );
  }
}

class SystemMessage {
  final String id;
  final String body;
  final String? url;
  final String? messageTimestampUtc;
  final bool isCompleted;
  final String? completedBy;
  final UserProfileModel? completedByUser;

  SystemMessage({
    required this.id,
    required this.body,
    this.url,
    this.messageTimestampUtc,
    required this.isCompleted,
    this.completedBy,
    this.completedByUser,
  });

  factory SystemMessage.fromJson(Map<String, dynamic> json) {
    return SystemMessage(
      id: json['id']?.toString() ?? '',
      body: json['body'] ?? '',
      url: json['url'],
      messageTimestampUtc: json['messageTimestampUtc'],
      isCompleted: json['isCompleted'] == true || json['isCompleted'] == 1,
      completedBy: json['completedBy'],
      completedByUser: json['completedByUser'] != null
          ? UserProfileModel.fromJson(json['completedByUser'])
          : null,
    );
  }
}

class StaffUserResponse {
  final List<UserProfileModel> users;

  StaffUserResponse({required this.users});

  factory StaffUserResponse.fromJson(Map<String, dynamic> json) {
    return StaffUserResponse(
      users: (json['users'] as List<dynamic>? ?? [])
          .map((e) => UserProfileModel.fromJson(e))
          .toList(),
    );
  }
}
