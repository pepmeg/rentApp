class ChatNotification {
  final String chatId;
  final String companionName;
  final String? companionAvatar;
  final String lastMessageText;
  int unreadCount;
  final DateTime firstTimestamp;
  DateTime lastTimestamp;

  ChatNotification({
    required this.chatId,
    required this.companionName,
    this.companionAvatar,
    required this.lastMessageText,
    this.unreadCount = 1,
    required this.firstTimestamp,
    required this.lastTimestamp,
  });
}