import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import '../../../models/messager_model/message.dart';
import '../../../models/user.dart';
import 'chat_message.dart';
import 'chat_unread_divider.dart';

class ChatMessageList extends StatelessWidget {
  final List<Message> messages;
  final AutoScrollController scrollController;
  final UserModel? currentUser;
  final UserModel? companion;
  final int? selectedMessageIndex;
  final int? selectedImageMessageIndex;
  final Set<int> selectedImageIndices;
  final bool showUnreadDivider;
  final int? unreadDividerMessageIndex;
  final bool isImageSelectionMode;
  final Function(int) onSelectMessage;
  final Function(int, int) onSelectImage;
  final Function(int, int) onImageLongPress;
  final bool isCurrentUserSupport;
  final void Function(int, int)? onImageTapGallery;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    this.currentUser,
    this.companion,
    required this.selectedMessageIndex,
    required this.selectedImageMessageIndex,
    required this.selectedImageIndices,
    required this.showUnreadDivider,
    required this.unreadDividerMessageIndex,
    required this.isImageSelectionMode,
    required this.onSelectMessage,
    required this.onSelectImage,
    required this.onImageLongPress,
    required this.isCurrentUserSupport,
    this.onImageTapGallery,
  });

  int _getItemCount() {
    return messages.length + (showUnreadDivider && unreadDividerMessageIndex != null ? 1 : 0);
  }

  bool _isDividerIndex(int index) {
    return showUnreadDivider && unreadDividerMessageIndex != null && index == unreadDividerMessageIndex;
  }

  int _toMessageIndex(int listIndex) {
    if (showUnreadDivider && unreadDividerMessageIndex != null && listIndex > unreadDividerMessageIndex!) {
      return listIndex - 1;
    }
    return listIndex;
  }

  bool _shouldShowDate(int index, List<Message> messages) {
    if (index == 0) return true;
    final prev = messages[index - 1].timestamp;
    final curr = messages[index].timestamp;
    return prev.day != curr.day || prev.month != curr.month || prev.year != curr.year;
  }

  String _formatMessageTime(DateTime utcTime) {
    final moscow = utcTime.add(const Duration(hours: 3));
    return DateFormat('HH:mm').format(moscow);
  }

  String _formatDate(DateTime utc) {
    final moscow = utc.add(const Duration(hours: 3));
    final nowUtc = DateTime.now().toUtc();
    final nowMoscow = nowUtc.add(const Duration(hours: 3));
    final today = DateTime(nowMoscow.year, nowMoscow.month, nowMoscow.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(moscow.year, moscow.month, moscow.day);
    if (dateToCheck == today) return 'Сегодня';
    if (dateToCheck == yesterday) return 'Вчера';
    return DateFormat('d MMMM', 'ru').format(moscow);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      itemCount: _getItemCount(),
      itemBuilder: (context, listIndex) {
        if (_isDividerIndex(listIndex)) return const ChatUnreadDivider();

        final msgIndex = _toMessageIndex(listIndex);
        final msg = messages[msgIndex];
        if (msg.moderated) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Сообщение удалено администратором',
                        style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final isMe = msg.senderId == currentUser?.uid;
        final showAvatar = msgIndex == 0 || messages[msgIndex - 1].senderId != msg.senderId;
        final showDate = _shouldShowDate(msgIndex, messages);
        final bool showTime = (msgIndex == messages.length - 1) ||
            (messages[msgIndex + 1].senderId != msg.senderId) ||
            (messages[msgIndex + 1].timestamp.difference(msg.timestamp).inMinutes >= 5) ||
            (messages[msgIndex + 1].timestamp.hour != msg.timestamp.hour) ||
            (messages[msgIndex + 1].timestamp.minute != msg.timestamp.minute);
        final bool forceRightForAi = isCurrentUserSupport && msg.senderId == 'ai_assistant';
        final timeString = _formatMessageTime(msg.timestamp);
        final selectedImageSet = (selectedImageMessageIndex == msgIndex) ? selectedImageIndices : <int>{};

        return AutoScrollTag(
          key: ValueKey(msgIndex),
          controller: scrollController,
          index: msgIndex,
          child: ChatMessageWidget(
            message: msg,
            isMe: isMe,
            showAvatar: showAvatar,
            showDate: showDate,
            showTime: showTime,
            dateText: _formatDate(msg.timestamp),
            timeText: timeString,
            companion: companion,
            isSelected: msgIndex == selectedMessageIndex,
            onLongPress: () => onSelectMessage(msgIndex),
            onImageLongPress: (imgIdx) => onImageLongPress(msgIndex, imgIdx),
            onImageTap: (imgIdx) {
              if (isImageSelectionMode) {
                onSelectImage(msgIndex, imgIdx);
              } else {
                onImageTapGallery?.call(msgIndex, imgIdx);
              }
            },
            selectedImageIndices: selectedImageSet,
            forceRightForAi: forceRightForAi,
          ),
        );
      },
    );
  }
}