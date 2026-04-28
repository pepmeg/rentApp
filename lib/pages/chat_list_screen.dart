import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:untitled/pages/chat_screen.dart';
import 'package:untitled/provider/AuthProvider.dart';
import 'package:untitled/provider/chat_provider.dart';
import 'package:untitled/models/user.dart';
import 'package:untitled/utils/colors.dart';
import 'dart:io';
import '../models/chat.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final chatProvider = context.watch<ChatProvider>();
    final chats = List<Chat>.from(chatProvider.getChatsForUser(user.id))
      ..sort((a, b) {
        final aTime = a.messages.isNotEmpty
            ? a.messages.last.timestamp
            : DateTime(0);
        final bTime = b.messages.isNotEmpty
            ? b.messages.last.timestamp
            : DateTime(0);
        return bTime.compareTo(aTime);
      });

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
                        size: 64,
                        color: AppColors.oliveGray.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('Нет сообщений',
                        style: TextStyle(
                            fontSize: 18,
                            color: AppColors.oliveGray.withOpacity(0.5))),
                    const SizedBox(height: 8),
                    Text('Напишите продавцу, чтобы начать общение',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.oliveGray.withOpacity(0.4))),
                  ],
                ),
              )
                  : ListView.separated(
                itemCount: chats.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final lastMessage = chat.messages.isNotEmpty
                      ? chat.messages.last
                      : null;
                  final isUnread = lastMessage != null &&
                      chatProvider.isChatUnread(chat.id, user.id);
                  final timeText = lastMessage != null
                      ? DateFormat('HH:mm').format(lastMessage.timestamp)
                      : '';
                  final productName = chat.productName ?? '';
                  final companionId = chat.user1Id == user.id
                      ? chat.user2Id
                      : chat.user1Id;
                  final futureUser = context
                      .read<AuthProvider>()
                      .getUserById(companionId);
                  final isSelected = _selectedChatIds.contains(chat.id);

                  return GestureDetector(
                    onTap: () {
                      if (_selectionMode) {
                        _toggleSelection(chat.id);
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ChatScreen(chat: chat)));
                      }
                    },
                    onLongPress: () {
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

                          Widget leading = CircleAvatar(
                            radius: 26,
                            backgroundColor:
                            AppColors.oliveGray.withOpacity(0.1),
                            child: const Icon(Icons.chat,
                                color: AppColors.oliveGray, size: 24),
                          );

                          if (chat.productImage != null &&
                              chat.productImage!.isNotEmpty) {
                            final path = chat.productImage!;
                            if (path.startsWith('assets/')) {
                              leading = ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(path,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover),
                              );
                            } else {
                              leading = ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(path),
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover),
                              );
                            }
                          } else if (companion?.avatarPath != null &&
                              companion!.avatarPath!.isNotEmpty) {
                            final avatarPath = companion.avatarPath!;
                            if (avatarPath.startsWith('assets/')) {
                              leading = CircleAvatar(
                                radius: 26,
                                backgroundImage: AssetImage(avatarPath),
                              );
                            } else {
                              leading = CircleAvatar(
                                radius: 26,
                                backgroundImage:
                                FileImage(File(avatarPath)),
                              );
                            }
                          }

                          return Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.center,
                            children: [
                              leading,
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.oliveGray),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (productName.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        productName,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors
                                                .oliveGray
                                                .withOpacity(0.7)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      lastMessage != null
                                          ? lastMessage.text
                                          : 'Нет сообщений',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.oliveGray
                                            .withOpacity(0.6),
                                        fontWeight: isUnread
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.end,
                                children: [
                                  if (timeText.isNotEmpty)
                                    Text(
                                      timeText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isUnread
                                            ? AppColors.copper
                                            : AppColors.oliveGray
                                            .withOpacity(0.5),
                                        fontWeight: isUnread
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  if (isUnread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin:
                                      const EdgeInsets.only(top: 2),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.copper,
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