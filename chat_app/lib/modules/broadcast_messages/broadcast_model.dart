import 'package:chat_app/modules/home/models/pagination_model.dart';
import 'package:chat_app/modules/home/models/user_profile_model.dart';

class BroadcastResponse {
  final List<BroadcastModel> messages;
  final PaginationModel pagination;

  BroadcastResponse({required this.messages, required this.pagination});

  factory BroadcastResponse.fromJson(Map<String, dynamic> json) {
    return BroadcastResponse(
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((e) => BroadcastModel.fromJson(e))
          .toList(),
      pagination: PaginationModel.fromJson(json['pagination'] ?? {}),
    );
  }
}

class BroadcastModel {
  final String id;
  final String body;
  final String? url;
  final int totalMessages;
  final int sentMessages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BroadcastMessage> broadcastMessages;

  BroadcastModel({
    required this.id,
    required this.body,
    this.url,
    required this.totalMessages,
    required this.sentMessages,
    required this.createdAt,
    required this.updatedAt,
    required this.broadcastMessages,
  });

  factory BroadcastModel.fromJson(Map<String, dynamic> json) {
    return BroadcastModel(
      id: json['id']?.toString() ?? '',
      body: json['body'] ?? '',
      url: json['url'],
      totalMessages: json['totalMessages'] ?? 0,
      sentMessages: json['sentMessages'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      broadcastMessages: (json['broadcast_messages'] as List<dynamic>? ?? [])
          .map((e) => BroadcastMessage.fromJson(e))
          .toList(),
    );
  }
}

class BroadcastMessage {
  final String id;
  final String broadcastMessageLogId;
  final String senderId;
  final String userId;
  final String body;
  final String? url;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfileModel userProfile;

  BroadcastMessage({
    required this.id,
    required this.broadcastMessageLogId,
    required this.senderId,
    required this.userId,
    required this.body,
    this.url,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.userProfile,
  });

  factory BroadcastMessage.fromJson(Map<String, dynamic> json) {
    return BroadcastMessage(
      id: json['id']?.toString() ?? '',
      broadcastMessageLogId: json['broadcast_message_log_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      body: json['body'] ?? '',
      url: json['url'],
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      userProfile: UserProfileModel.fromJson(json['userProfile'] ?? {}),
    );
  }
}
