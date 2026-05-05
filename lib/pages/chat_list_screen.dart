import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/messager_model/chat.dart';
import '../../models/user.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/chat_provider.dart';
import '../../utils/colors.dart';
import '../utils/avatar.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedChatIds = {};

  void _toggleSelection(String chatId) {
    setState(() {
      if (_selectedChatIds.contains(chatId)) {
        _selectedChatIds.remove(chatId);
        if (_selectedChatIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedChatIds.add(chatId);
      }
    });
  }

  void _enterSelectionMode(String chatId) {
    setState(() {
      _selectionMode = true;
      _selectedChatIds.add(chatId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedChatIds.clear();
    });
  }

  void _deleteSelectedChats() {
    if (_selectedChatIds.isEmpty) return;
    context.read<ChatProvider>().deleteChats(_selectedChatIds);
    _exitSelectionMode();
  }

  String _formatLastMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == yesterday) {
      return 'Вчера';
    } else if (dateTime.year == now.year) {
      return DateFormat('d MMMM', 'ru').format(dateTime);
    } else {
      return DateFormat('d MMMM yyyy', 'ru').format(dateTime);
    }
  }

  Widget _buildLastMessagePreview(Chat chat) {
    if (chat.messages.isEmpty) return const Text('Нет сообщений');
    final last = chat.messages.last;

    if (last.text.isNotEmpty) {
      return Text(
        last.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.oliveGray.withOpacity(0.5),
          fontWeight: FontWeight.normal,
        ),
      );
    }

    if (last.images != null && last.images!.isNotEmpty) {
      final images = last.images!;
      final count = images.length;
      final label = count == 1 ? 'Фотоография' : '$count фото';

      final thumbnails = images.take(3).toList();

      return Row(
        children: [
          ...thumbnails.map((path) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: path.startsWith('assets/')
                  ? Image.asset(
                path,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              )
                  : Image.file(
                File(path),
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
          )),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.oliveGray.withOpacity(0.5),
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      );
    }

    return const Text('Нет сообщений');
  }

  Chat? _getOrCreateChatBetween(int userId1, int userId2, BuildContext context, String companionName) {
    final chatProvider = context.read<ChatProvider>();
    final existingChat = chatProvider.getChatsForUser(userId1).cast<Chat?>().firstWhere(
          (c) => (c!.user1Id == userId1 && c.user2Id == userId2) ||
          (c.user1Id == userId2 && c.user2Id == userId1),
      orElse: () => null,
    );
    if (existingChat != null) return existingChat;

    return chatProvider.getOrCreateChat(
      userId1,
      userId2,
      productId: null,
      companionName: companionName,
      companionAvatar: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final chatProvider = context.watch<ChatProvider>();
    final List<Chat> allUserChats = List<Chat>.from(chatProvider.getChatsForUser(user.id));
    final role = user.role;

    final List<Chat> pinnedChats = [];

    if (role == 'support') {
      const adminId = 999;
      final adminChat = _getOrCreateChatBetween(user.id, adminId, context, 'Администратор');
      if (adminChat != null && !pinnedChats.any((c) => c.id == adminChat.id)) {
        pinnedChats.add(adminChat);
      }
    } else if (role == 'admin') {
      const supportId = 0;
      final supportChat = _getOrCreateChatBetween(user.id, supportId, context, 'Поддержка');
      if (supportChat != null && !pinnedChats.any((c) => c.id == supportChat.id)) {
        pinnedChats.add(supportChat);
      }
    } else if (role == 'user') {
      final supportUser = context.read<AuthProvider>().getSupportUserSync();
      if (supportUser != null) {
        final supportChat = _getOrCreateChatBetween(user.id, supportUser.id, context, 'Поддержка');
        if (supportChat != null && !pinnedChats.any((c) => c.id == supportChat.id)) {
          pinnedChats.add(supportChat);
        }
      }
    }

    final Set<String> pinnedIds = pinnedChats.map((c) => c.id).toSet();
    final List<Chat> regularChats = allUserChats.where((c) => !pinnedIds.contains(c.id)).toList();

    regularChats.sort((a, b) {
      final aTime = a.messages.isNotEmpty ? a.messages.last.timestamp : DateTime(0);
      final bTime = b.messages.isNotEmpty ? b.messages.last.timestamp : DateTime(0);
      return bTime.compareTo(aTime);
    });

    final List<Chat> chats = [...pinnedChats, ...regularChats];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 15),
            Expanded(
              child: chats.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 64, color: AppColors.oliveGray.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('Нет сообщений',
                        style: TextStyle(
                            fontSize: 18, color: AppColors.oliveGray.withOpacity(0.5))),
                    const SizedBox(height: 8),
                    Text('Напишите продавцу, чтобы начать общение',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.oliveGray.withOpacity(0.4))),
                  ],
                ),
              )
                  : ListView.separated(
                itemCount: chats.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final lastMessage = chat.messages.isNotEmpty ? chat.messages.last : null;
                  final isUnread = lastMessage != null && chatProvider.isChatUnread(chat.id, user.id);
                  final timeText = lastMessage != null ? _formatLastMessageTime(lastMessage.timestamp) : '';
                  final productName = chat.productName ?? '';
                  final companionId = chat.user1Id == user.id ? chat.user2Id : chat.user1Id;
                  final futureUser = context.read<AuthProvider>().getUserById(companionId);
                  final isSelected = _selectedChatIds.contains(chat.id);
                  // Служебный чат с администратором/поддержкой
                  final bool isSupportAdminChat =
                      chat.user1Id == 0 || chat.user2Id == 0 ||
                          chat.user1Id == 999 || chat.user2Id == 999;

                  return GestureDetector(
                    onTap: () {
                      if (_selectionMode) {
                        if (!isSupportAdminChat) {
                          _toggleSelection(chat.id);
                        }
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ChatScreen(chat: chat)));
                      }
                    },
                    onLongPress: isSupportAdminChat
                        ? null
                        : () {
                      if (!_selectionMode) {
                        _enterSelectionMode(chat.id);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.copper.withOpacity(0.1)
                            : AppColors.whiteAntique,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: FutureBuilder<UserModel?>(
                        future: futureUser,
                        builder: (ctx, snapshot) {
                          final companion = snapshot.data;
                          final name = companion != null
                              ? '${companion.firstName} ${companion.lastName}'
                              : (chat.companionName ?? 'Собеседник');
                          final unreadCount = chatProvider.unreadMessageCount(chat.id, user.id);

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
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.oliveGray),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (productName.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(productName,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.normal,
                                            color: AppColors.oliveGray),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    _buildLastMessagePreview(chat),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (timeText.isNotEmpty)
                                    Text(timeText,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isUnread ? AppColors.copper : AppColors.oliveGray.withOpacity(0.5),
                                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                        )),
                                  const SizedBox(height: 4),
                                  if (unreadCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      margin: const EdgeInsets.only(top: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.copper,
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Сообщения',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.oliveGray,
          ),
        ),
        if (_selectionMode) _buildActionBar(),
      ],
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _exitSelectionMode,
            child: const Icon(Icons.close, size: 28, color: AppColors.oliveGray),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _selectedChatIds.isEmpty ? null : _deleteSelectedChats,
            child: Icon(
              Icons.delete,
              size: 28,
              color: _selectedChatIds.isEmpty
                  ? AppColors.oliveGray.withOpacity(0.5)
                  : AppColors.oliveGray,
            ),
          ),
        ],
      ),
    );
  }
}