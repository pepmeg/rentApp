import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:untitled/models/chat.dart';
import 'package:untitled/models/message.dart';
import 'package:untitled/models/user.dart';
import 'package:untitled/models/product.dart';
import 'package:untitled/pages/productScreen.dart';
import 'package:untitled/provider/AuthProvider.dart';
import 'package:untitled/provider/chat_provider.dart';
import 'package:untitled/data/product_data.dart';
import 'package:untitled/utils/colors.dart';
import 'dart:io';
import '../provider/bottom_nav_provider.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  const ChatScreen({required this.chat, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  UserModel? _companion;
  Product? _product;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<ChatProvider>().markChatAsRead(widget.chat.id, user.id);
      }
    });
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final companionId = widget.chat.user1Id == user.id
        ? widget.chat.user2Id
        : widget.chat.user1Id;

    final authProvider = context.read<AuthProvider>();
    final companion = await authProvider.getUserById(companionId);
    final product = widget.chat.productId != null
        ? ProductData.getProductById(widget.chat.productId!)
        : null;

    if (mounted) {
      setState(() {
        _companion = companion;
        _product = product;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final message = Message(
      senderId: user.id,
      text: text,
      timestamp: DateTime.now(),
    );

    context.read<ChatProvider>().sendMessage(widget.chat.id, message);
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Сегодня';
    }
    return DateFormat('d MMMM', 'ru').format(date);
  }

  bool _shouldShowDate(int index, List<Message> messages) {
    if (index == 0) return true;
    final prev = messages[index - 1].timestamp;
    final curr = messages[index].timestamp;
    return prev.day != curr.day || prev.month != curr.month || prev.year != curr.year;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final chat = context.watch<ChatProvider>().getChatById(widget.chat.id);
    final messages = chat?.messages ?? widget.chat.messages;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(left: 10, right: 10, top: 40, bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.whiteAntique,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_companion != null) {
                      context.read<BottomNavProvider>().showUserProfile(_companion!.id);
                      Navigator.pop(context);
                    }
                  },
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 24, color: AppColors.oliveGray),
                        onPressed: () => Navigator.pop(context),
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.oliveGray.withOpacity(0.1),
                        backgroundImage: _companion?.avatarPath != null
                            ? FileImage(File(_companion!.avatarPath!))
                            : null,
                        child: _companion?.avatarPath == null
                            ? const Icon(Icons.person, color: AppColors.oliveGray, size: 24)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_companion?.firstName ?? 'Продавец'} ${_companion?.lastName ?? ''}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.oliveGray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _product != null ? 'По товару' : 'Чат',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.oliveGray.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_product != null) ...[
                  const SizedBox(height: 8),
                  Divider(color: AppColors.oliveGray.withOpacity(0.2), height: 1),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductScreen(product: _product!),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _product!.images.isNotEmpty
                                ? (_product!.images[0].startsWith('assets/')
                                ? Image.asset(_product!.images[0], width: 48, height: 48, fit: BoxFit.cover)
                                : Image.file(File(_product!.images[0]), width: 48, height: 48, fit: BoxFit.cover))
                                : Container(
                              width: 48,
                              height: 48,
                              color: AppColors.oliveGray.withOpacity(0.1),
                              child: const Icon(Icons.image, color: AppColors.oliveGray, size: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _product!.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.oliveGray,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_product!.price} ₽',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.oliveGray.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? Center(
              child: Text(
                'Нет сообщений. Начните общение!',
                style: TextStyle(color: AppColors.oliveGray.withOpacity(0.5)),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg.senderId == user?.id;
                final showAvatar = index == 0 ||
                    messages[index - 1].senderId != msg.senderId;
                final showDate = _shouldShowDate(index, messages);
                final bool showTime;
                if (index == messages.length - 1) {
                  showTime = true;
                } else {
                  final next = messages[index + 1].timestamp;
                  final curr = msg.timestamp;
                  showTime = next.minute != curr.minute ||
                      next.hour != curr.hour ||
                      next.day != curr.day ||
                      next.month != curr.month ||
                      next.year != curr.year;
                }
                final timeString = DateFormat('HH:mm').format(msg.timestamp);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (showDate)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.oliveGray.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatDate(msg.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.oliveGray.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe && showAvatar)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.oliveGray.withOpacity(0.1),
                                backgroundImage: _companion?.avatarPath != null
                                    ? FileImage(File(_companion!.avatarPath!))
                                    : null,
                                child: _companion?.avatarPath == null
                                    ? const Icon(Icons.person, size: 18, color: AppColors.oliveGray)
                                    : null,
                              ),
                            )
                          else if (!isMe)
                            const SizedBox(width: 40),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppColors.copper.withOpacity(0.15) : AppColors.whiteAntique,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
                                      bottomRight: isMe ? Radius.zero : const Radius.circular(18),
                                    ),
                                  ),
                                  child: Text(
                                    msg.text,
                                    style: const TextStyle(fontSize: 15, color: AppColors.oliveGray),
                                    softWrap: true,
                                  ),
                                ),
                                if (showTime)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 2,
                                      left: isMe ? 0 : 3,
                                      right: isMe ? 10 : 0,
                                    ),
                                    child: Text(
                                      timeString,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.oliveGray.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: 6,
                    minLines: 1,
                    style: const TextStyle(color: AppColors.oliveGray),
                    decoration: InputDecoration(
                      hintText: 'Сообщение...',
                      hintStyle: TextStyle(color: AppColors.oliveGray.withOpacity(0.4)),
                      filled: true,
                      fillColor: AppColors.whiteAntique,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.copper,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.arrow_upward, color: AppColors.whiteAntique, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}