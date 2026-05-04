class Message {
  final int senderId;
  final String text;
  final DateTime timestamp;
  final List<String>? images;
  final bool edited;
  final bool moderated;

  Message({
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.images,
    this.edited = false,
    this.moderated = false,
  });

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    if (images != null) 'images': images,
    if (edited) 'edited': true,
    if (moderated) 'moderated': true,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    senderId: json['senderId'],
    text: json['text'],
    timestamp: DateTime.parse(json['timestamp']),
    images: json['images'] != null ? List<String>.from(json['images']) : null,
    edited: json['edited'] ?? false,
    moderated: json['moderated'] ?? false,
  );
}