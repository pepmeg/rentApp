import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/messager_model/chat.dart';
import '../../models/user.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/chat_provider.dart';
import '../../utils/colors.dart';
import '../../utils/avatar.dart';
import '../chat_screen.dart';

class AdminChatsTab extends StatelessWidget {
  const AdminChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.read<AuthProvider>();
    final List<Chat> allChats = chatProvider.getAllChats();
    final Set<String> seen = {};
    final uniqueChats = allChats.where((chat) {
      final List<int> ids = [chat.user1Id, chat.user2Id]..sort();
      final key = '${ids[0]}_${ids[1]}_${chat.productId ?? 0}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    return ListView.builder(
      itemCount: uniqueChats.length,
      itemBuilder: (context, index) {
        final chat = uniqueChats[index];
        final user1Future = authProvider.getUserById(chat.user1Id);
        final user2Future = authProvider.getUserById(chat.user2Id);

        final bool isSupportAdminChat =
            (chat.user1Id == 0 && chat.user2Id == 999) ||
                (chat.user1Id == 999 && chat.user2Id == 0);

        return Card(
          color: AppColors.whiteAntique,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: FutureBuilder(
            future: Future.wait([user1Future, user2Future]),
            builder: (ctx, AsyncSnapshot<List<UserModel?>> snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final user1 = snapshot.data![0];
              final user2 = snapshot.data![1];
              final name1 = user1 != null ? '${user1.firstName} ${user1.lastName}' : 'Пользователь ${chat.user1Id}';
              final name2 = user2 != null ? '${user2.firstName} ${user2.lastName}' : 'Пользователь ${chat.user2Id}';
              final title = '$name1 – $name2';
              final lastMsg = chat.messages.isNotEmpty ? chat.messages.last : null;
              final timeText = lastMsg != null ? _formatTime(lastMsg.timestamp) : '';

              return ListTile(
                leading: buildUserAvatar(
                  user1,
                  fallbackImage: chat.productImage,
                  fallbackIcon: Icons.chat,
                  radius: 24,
                ),
                title: Text(title, style: const TextStyle(color: AppColors.oliveGray)),
                subtitle: Text(
                  lastMsg != null
                      ? (lastMsg.text.isNotEmpty ? lastMsg.text : '[Фото]')
                      : 'Нет сообщений',
                  style: TextStyle(color: AppColors.oliveGray.withOpacity(0.7)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (timeText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(timeText, style: TextStyle(color: AppColors.oliveGray.withOpacity(0.5), fontSize: 12)),
                      ),
                    if (!isSupportAdminChat)
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.whiteAntique,
                              title: const Text('Удалить чат?', style: TextStyle(color: AppColors.oliveGray)),
                              content: const Text('Все сообщения будут удалены.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                                TextButton(
                                  onPressed: () {
                                    chatProvider.deleteChats({chat.id});
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Удалить', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.delete, size: 18, color: AppColors.oliveGray),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
                },
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(dt.year, dt.month, dt.day);
    if (msgDate == today) return DateFormat('HH:mm').format(dt);
    final yesterday = today.subtract(const Duration(days: 1));
    if (msgDate == yesterday) return 'Вчера';
    if (dt.year == now.year) {
      return DateFormat('d MMMM', 'ru').format(dt);
    }
    return DateFormat('d MMMM yyyy', 'ru').format(dt);
  }
}