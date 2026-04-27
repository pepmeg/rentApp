import 'message.dart';

class Chat {
  final String id;
  final int user1Id;
  final int user2Id;
  final int? productId;
  final String? productName;
  final String? productImage;
  final String? companionName;
  final String? companionAvatar;
  final List<Message> messages;

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
  };

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
    id: json['id'],
    user1Id: json['user1Id'],
    user2Id: json['user2Id'],
    productId: json['productId'],
    productName: json['productName'],
    productImage: json['productImage'],
    companionName: json['companionName'],
    companionAvatar: json['companionAvatar'],
    messages: (json['messages'] as List)
        .map((m) => Message.fromJson(m))
        .toList(),
  );
}