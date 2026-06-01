import 'message.dart';

class Chat {
  final String id;
  final String user1Id;
  final String user2Id;
  final int? productId;
  final String? productName;
  final String? productImage;
  final String? companionName;
  final String? companionAvatar;
  final List<Message> messages;
  final bool aiMode;
  final bool humanRequested;
  final String? assignedOperatorId;
  String? companionRole;

  Chat({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.productId,
    this.productName,
    this.productImage,
    this.companionName,
    this.companionAvatar,
    List<Message>? messages,
    this.aiMode = true,
    this.humanRequested = false,
    this.assignedOperatorId,
    this.companionRole,
  }) : messages = messages ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'user1Id': user1Id,
    'user2Id': user2Id,
    'productId': productId,
    'productName': productName,
    'productImage': productImage,
    'companionName': companionName,
    'companionAvatar': companionAvatar,
    'messages': messages.map((m) => m.toJson()).toList(),
    'aiMode': aiMode,
    'humanRequested': humanRequested,
    'assignedOperatorId': assignedOperatorId,
  };

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
    id: json['id'] as String,
    user1Id: json['user1Id'] as String? ?? '',
    user2Id: json['user2Id'] as String? ?? '',
    productId: json['productId'] as int?,
    productName: json['productName'] as String?,
    productImage: json['productImage'] as String?,
    companionName: json['companionName'] as String?,
    companionAvatar: json['companionAvatar'] as String?,
    messages: (json['messages'] as List? ?? [])
        .map((m) => Message.fromJson(m))
        .toList(),
    aiMode: json['aiMode'] as bool? ?? true,
    humanRequested: json['humanRequested'] as bool? ?? false,
    assignedOperatorId: json['assignedOperatorId'] as String?,
    companionRole: null,
  );
}