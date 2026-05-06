import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/messager_model/chat.dart';
import '../../models/user.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/chat_provider.dart';
import '../../utils/colors.dart';
import '../../utils/avatar.dart';
import '../../utils/pagination.dart';
import '../chat_screen.dart';

class AdminChatsTab extends StatefulWidget {
  const AdminChatsTab({super.key});

  @override
  State<AdminChatsTab> createState() => _AdminChatsTabState();
}

class _AdminChatsTabState extends State<AdminChatsTab> with PaginationMixin {
  String _searchQuery = '';

  @override
  int get paginationBatchSize => 10;

  @override
  List<dynamic> get paginationItems => _filteredChats;

  List<Chat> get _filteredChats {
    final chatProvider = context.read<ChatProvider>();
    final List<Chat> allChats = chatProvider.getAllChats();
    final Set<String> seen = {};
    var uniqueChats = allChats.where((chat) {
      final List<int> ids = [chat.user1Id, chat.user2Id]..sort();
      final key = '${ids[0]}_${ids[1]}_${chat.productId ?? 0}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    var filtered = _searchQuery.isEmpty
        ? uniqueChats
        : uniqueChats.where((chat) {
      final query = _searchQuery.toLowerCase();
      if (chat.productName != null && chat.productName!.toLowerCase().contains(query)) {
        return true;
      }
      if (chat.messages.isNotEmpty) {
        final lastMsg = chat.messages.last;
        if (lastMsg.text.isNotEmpty && lastMsg.text.toLowerCase().contains(query)) {
          return true;
        }
      }
      return false;
    }).toList();

    filtered.sort((a, b) {
      final aTime = a.messages.isNotEmpty ? a.messages.last.timestamp : DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.messages.isNotEmpty ? b.messages.last.timestamp : DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final allItems = _filteredChats;
    final visibleItems = allItems.take(visibleCount).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
                resetPagination();
              },
              decoration: InputDecoration(
                hintText: 'Поиск чатов',
                hintStyle: TextStyle(color: AppColors.oliveGray.withOpacity(0.5), fontSize: 16),
                prefixIcon: Icon(Icons.search, color: AppColors.copper),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: AppColors.oliveGray.withOpacity(0.5)),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    resetPagination();
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: visibleItems.length,
            itemBuilder: (context, index) {
              final chat = visibleItems[index];
              final user1Future = authProvider.getUserById(chat.user1Id);
              final user2Future = authProvider.getUserById(chat.user2Id);

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

                    // Проверяем, участвует ли в чате администратор или поддержка
                    final isPrivilegedChat = (user1 != null &&
                        (user1!.role == 'admin' || user1!.role == 'support')) ||
                        (user2 != null &&
                            (user2!.role == 'admin' || user2!.role == 'support'));

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
                          if (!isPrivilegedChat)   // <--- новое условие
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
          ),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(color: AppColors.copper)),
          ),
      ],
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