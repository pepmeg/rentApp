import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final List<String>? images;
  final bool edited;
  final bool moderated;
  final String? clientId;

  Message({
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.images,
    this.edited = false,
    this.moderated = false,
    this.clientId,
  });

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    if (images != null) 'images': images,
    if (edited) 'edited': true,
    if (moderated) 'moderated': true,
    if (clientId != null) 'clientId': clientId,
  };

  factory Message.fromJson(Map<String, dynamic> json) {
    DateTime msgTime;
    final rawTimestamp = json['timestamp'];
    if (rawTimestamp is Timestamp) {
      msgTime = rawTimestamp.toDate().toUtc();
    } else if (rawTimestamp is String) {
      msgTime = DateTime.tryParse(rawTimestamp + 'Z')?.toUtc() ?? DateTime.now().toUtc();
    } else {
      msgTime = DateTime.now().toUtc();
    }

    return Message(
      senderId: json['senderId']?.toString() ?? '',
      text: json['text'] as String? ?? '',
      timestamp: msgTime,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      edited: json['edited'] as bool? ?? false,
      moderated: json['moderated'] as bool? ?? false,
      clientId: json['clientId'] as String?,
    );
  }
}