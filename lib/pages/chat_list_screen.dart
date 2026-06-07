import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/messager_model/chat.dart';
import '../provider/AuthProvider.dart';
import '../provider/chat_provider.dart';
import '../utils/chat_list_header.dart';
import '../widgets/chat/chat_list_item.dart';
import '../widgets/empty_state.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedChatIds = {};
  String? _lastUserId;
  bool _isManualRefresh = false;
  bool _initialLoadDone = false;

  List<Chat> _cachedSortedChats = [];
  String? _cachedChatsSignature;

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
        _cachedSortedChats = [];
        _cachedChatsSignature = null;
        _loadChatsAndPinned();
      }
    } else if (userId == null && _lastUserId != null) {
      _lastUserId = null;
      setState(() {
        _cachedSortedChats = [];
        _cachedChatsSignature = null;
      });
    }
  }

  Future<void> _loadChatsAndPinned() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    await _ensurePinnedChatsLoaded(user.uid);
    await context.read<ChatProvider>().loadChatsForUser(user.uid);

    _initialLoadDone = true;
    if (mounted) {
      _cachedChatsSignature = null;
      setState(() {});
    }
  }

  Future<void> _ensurePinnedChatsLoaded(String userId) async {
    final chatProvider = context.read<ChatProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    String? companionUid;
    final role = user.role;

    try {
      if (role == 'admin' || role == 'user') {
        companionUid = await auth.getSupportUid();
      } else if (role == 'support') {
        companionUid = await auth.getAdminUid();
      }

      if (companionUid != null) {
        final existing = chatProvider.getChatsForUser(userId).where((c) {
          return (c.user1Id == userId && c.user2Id == companionUid) ||
              (c.user2Id == userId && c.user1Id == companionUid);
        }).toList();

        if (existing.isEmpty) {
          final companion = await auth.getUserById(companionUid);
          final companionName = companion != null
              ? '${companion.firstName} ${companion.lastName}'
              : (role == 'support' ? 'Администратор' : 'Поддержка');

          await chatProvider.getOrCreateChat(
            userId,
            companionUid,
            productId: null,
            companionName: companionName,
            companionAvatar: companion?.avatarUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('Ошибка подготовки закрепленного чата: $e');
    }
  }

  Future<void> _refresh() async {
    setState(() => _isManualRefresh = true);
    try {
      _cachedChatsSignature = null;
      await _loadChatsAndPinned();
    } finally {
      if (mounted) setState(() => _isManualRefresh = false);
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

  List<Chat> _buildSortedChats(String userId, List<Chat> allChats) {
    final signature = allChats.map((c) {
      final lastTime = c.messages.isNotEmpty
          ? c.messages.last.timestamp.millisecondsSinceEpoch
          : 0;
      final role = c.companionRole ?? '';
      return '${c.id}_${lastTime}_$role';
    }).join('|');
    if (signature == _cachedChatsSignature && _cachedSortedChats.isNotEmpty) {
      return _cachedSortedChats;
    }
    final Set<String> pinnedIds = {};
    final List<Chat> pinned = [];
    final List<Chat> regular = [];

    for (final chat in allChats) {
      final role = chat.companionRole;
      final bool isPinned = role == 'admin' || role == 'support';

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
      final timeCompare = bTime.compareTo(aTime);
      if (timeCompare != 0) return timeCompare;
      return a.id.compareTo(b.id);
    });

    _cachedSortedChats = [...pinned, ...regular];
    _cachedChatsSignature = signature;
    return _cachedSortedChats;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final chatProvider = context.watch<ChatProvider>();
    final allUserChats = chatProvider.getChatsForUser(user.uid);
    final isLoading = (chatProvider.isLoadingChats && allUserChats.isEmpty) || _isManualRefresh;
    final chats = _buildSortedChats(user.uid, allUserChats);
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: theme.primaryColor,
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                    : chats.isEmpty
                    ? EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: user.role == 'support' || user.role == 'admin'
                      ? 'Нет доступных чатов'
                      : 'Нет сообщений',
                  subtitle: user.role == 'support' || user.role == 'admin'
                      ? 'Потяните вниз, чтобы обновить'
                      : 'Напишите продавцу, чтобы начать общение',
                )
                    : ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final isSelected = _selectedChatIds.contains(chat.id);
                    final bool isSupportAdminChat =
                        chat.user1Id == '0' ||
                            chat.user2Id == '0' ||
                            chat.user1Id == '999' ||
                            chat.user2Id == '999';
                    final isPinned = chat.companionRole == 'admin' ||
                        chat.companionRole == 'support';

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < chats.length - 1 ? 8 : 0,
                      ),
                      child: ChatListItem(
                        key: ValueKey('chat_${chat.id}'),
                        chat: chat,
                        isSelected: isSelected,
                        selectionMode: _selectionMode,
                        currentUserId: user.uid,
                        isPinned: isPinned,
                        onTap: () => _toggleSelection(chat.id),
                        onLongPress: !isSupportAdminChat
                            ? () {
                          if (!_selectionMode) _enterSelectionMode(chat.id);
                        }
                            : null,
                      ),
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