import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/messager_model/chat.dart';
import '../provider/AuthProvider.dart';
import '../provider/chat_provider.dart';
import '../utils/chat_list_header.dart';
import '../widgets/chat/chat_list_item.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedChatIds = {};
  List<Chat>? _pinnedChats;
  bool _isLoadingPinned = true;
  bool _pinnedLoadingStarted = false;
  String? _lastUserId;
  bool _isManualRefresh = false;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatsAndPinned();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().currentUser;
    final userId = user?.uid;
    if (userId != null && userId != _lastUserId) {
      _lastUserId = userId;
      if (_initialLoadDone) {
        _loadChatsAndPinned();
      }
    } else if (userId == null && _lastUserId != null) {
      _lastUserId = null;
      setState(() {
        _pinnedChats = null;
        _isLoadingPinned = false;
      });
    }
  }

  Future<void> _loadChatsAndPinned() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await context.read<ChatProvider>().loadChatsForUser(user.uid);
    if (!_pinnedLoadingStarted) {
      await _loadPinnedChats();
    }
    _initialLoadDone = true;
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    setState(() => _isManualRefresh = true);
    try {
      await _loadChatsAndPinned();
    } finally {
      if (mounted) setState(() => _isManualRefresh = false);
    }
  }

  Future<void> _loadPinnedChats() async {
    if (_pinnedLoadingStarted) return;
    _pinnedLoadingStarted = true;
    setState(() => _isLoadingPinned = true);

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      setState(() => _isLoadingPinned = false);
      return;
    }

    final List<Chat> pinned = [];
    final role = user.role;
    final auth = context.read<AuthProvider>();

    try {
      if (role == 'admin') {
        final supportUid = await auth.getSupportUid();
        if (supportUid != null) {
          final supportChat = await _getOrCreateChatBetween(user.uid, supportUid);
          if (supportChat != null && !pinned.any((c) => c.id == supportChat.id)) {
            pinned.add(supportChat);
          }
        }
      } else if (role == 'support') {
        final adminUid = await auth.getAdminUid();
        if (adminUid != null) {
          final adminChat = await _getOrCreateChatBetween(user.uid, adminUid);
          if (adminChat != null && !pinned.any((c) => c.id == adminChat.id)) {
            pinned.add(adminChat);
          }
        }
      } else if (role == 'user') {
        final supportUid = await auth.getSupportUid();
        if (supportUid != null) {
          final supportChat = await _getOrCreateChatBetween(user.uid, supportUid);
          if (supportChat != null && !pinned.any((c) => c.id == supportChat.id)) {
            pinned.add(supportChat);
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка загрузки закреплённых чатов: $e');
    }

    if (mounted) {
      setState(() {
        _pinnedChats = pinned;
        _isLoadingPinned = false;
      });
    }
  }

  Future<Chat?> _getOrCreateChatBetween(String userId1, String userId2) async {
    final chatProvider = context.read<ChatProvider>();
    for (final chat in chatProvider.getChatsForUser(userId1)) {
      if ((chat.user1Id == userId1 && chat.user2Id == userId2) ||
          (chat.user1Id == userId2 && chat.user2Id == userId1)) {
        return chat;
      }
    }

    final companion = await context.read<AuthProvider>().getUserById(userId2);
    final companionName = companion != null ? '${companion.firstName} ${companion.lastName}' : 'Собеседник';

    try {
      return await chatProvider.getOrCreateChat(
        userId1,
        userId2,
        productId: null,
        companionName: companionName,
        companionAvatar: companion?.avatarUrl,
      );
    } catch (e) {
      debugPrint('Ошибка создания чата между $userId1 и $userId2: $e');
      return null;
    }
  }

  void _toggleSelection(String chatId) {
    setState(() {
      if (_selectedChatIds.contains(chatId)) {
        _selectedChatIds.remove(chatId);
        if (_selectedChatIds.isEmpty) _selectionMode = false;
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
    context.read<ChatProvider>().deleteChats(Set<String>.from(_selectedChatIds));
    _exitSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final chatProvider = context.watch<ChatProvider>();
    final allUserChats = chatProvider.getChatsForUser(user.uid);
    final isLoading = (chatProvider.isLoadingChats && allUserChats.isEmpty) || _isManualRefresh;

    final Set<String> pinnedIds = {};
    final List<Chat> pinned = [];
    final List<Chat> regular = [];

    for (final chat in allUserChats) {
      final bool isPinned = chat.companionRole == 'admin' || chat.companionRole == 'support';
      if (isPinned && !pinnedIds.contains(chat.id)) {
        pinned.add(chat);
        pinnedIds.add(chat.id);
      } else {
        regular.add(chat);
      }
    }

    regular.sort((a, b) {
      final aTime = a.messages.isNotEmpty ? a.messages.last.timestamp : DateTime(0);
      final bTime = b.messages.isNotEmpty ? b.messages.last.timestamp : DateTime(0);
      return bTime.compareTo(aTime);
    });

    final chats = [...pinned, ...regular];
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChatListHeader(
              selectionMode: _selectionMode,
              selectedCount: _selectedChatIds.length,
              onCloseSelection: _exitSelectionMode,
              onDeleteSelected: _deleteSelectedChats,
            ),
            const SizedBox(height: 15),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: theme.primaryColor,
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                    : chats.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.role == 'support' || user.role == 'admin'
                            ? 'Нет доступных чатов'
                            : 'Нет сообщений',
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.role == 'support' || user.role == 'admin'
                            ? 'Потяните вниз, чтобы обновить'
                            : 'Напишите продавцу, чтобы начать общение',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final isSelected = _selectedChatIds.contains(chat.id);
                    final bool isSupportAdminChat = chat.user1Id == '0' || chat.user2Id == '0' || chat.user1Id == '999' || chat.user2Id == '999';

                    return ChatListItem(
                      chat: chat,
                      isSelected: isSelected,
                      selectionMode: _selectionMode,
                      onTap: () => _toggleSelection(chat.id),
                      onLongPress: !isSupportAdminChat
                          ? () {
                        if (!_selectionMode) _enterSelectionMode(chat.id);
                      }
                          : null,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}