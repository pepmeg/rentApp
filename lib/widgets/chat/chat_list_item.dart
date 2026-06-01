import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/messager_model/chat.dart';
import '../../models/user.dart';
import '../../pages/chat_screen.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/chat_provider.dart';
import '../../utils/avatar.dart';
import '../../utils/chat_time_utils.dart';
import 'chat_last_message_preview.dart';

class ChatListItem extends StatelessWidget {
  final Chat chat;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final chatProvider = context.watch<ChatProvider>();
    final lastMessage = chat.messages.isNotEmpty ? chat.messages.last : null;
    final isUnread = lastMessage != null && chatProvider.isChatUnread(chat.id, user.uid);
    final timeText = lastMessage != null ? formatLastMessageTime(lastMessage.timestamp) : '';
    final productName = chat.productName ?? '';
    final companionId = chat.user1Id == user.uid ? chat.user2Id : chat.user1Id;
    final futureUser = context.read<AuthProvider>().getUserById(companionId);
    final bool isSupportAdminChat = chat.user1Id == '0' || chat.user2Id == '0' || chat.user1Id == '999' || chat.user2Id == '999';

    final bool canSelect = selectionMode && !isSupportAdminChat;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        if (selectionMode && canSelect) {
          onTap();
        } else if (!selectionMode) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
        }
      },
      onLongPress: isSupportAdminChat ? null : onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withOpacity(0.1)
              : (theme.cardTheme.color ?? theme.colorScheme.surface),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FutureBuilder<UserModel?>(
          future: futureUser,
          builder: (ctx, snapshot) {
            final companion = snapshot.data;
            final name = companion != null
                ? '${companion.firstName} ${companion.lastName}'
                : (chat.companionName ?? 'Собеседник');
            final unreadCount = chatProvider.unreadMessageCount(chat.id, user.uid);

            final leading = buildUserAvatar(
              companion,
              fallbackImage: chat.productImage,
              fallbackIcon: Icons.chat,
              radius: 26,
            );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                leading,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (productName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          productName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      ChatLastMessagePreview(
                        images: lastMessage?.images,
                        text: lastMessage?.text ?? '',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (timeText.isNotEmpty)
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread
                              ? theme.primaryColor
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}