import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import '../services/connectivityService.dart';
import '../services/product_service.dart';
import '../models/messager_model/chat.dart';
import '../models/messager_model/message.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../provider/AuthProvider.dart';
import '../provider/bottom_nav_provider.dart';
import '../provider/chat_provider.dart';
import '../services/storage_service.dart';
import '../utils/snackbar_custom.dart';
import '../services/ai_assistant.dart';
import '../widgets/chat/chat_header.dart';
import '../widgets/chat/chat_input.dart';
import '../services/notification_service.dart';
import '../widgets/chat/chat_message_list.dart';
import '../widgets/chat/image_viewer.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  const ChatScreen({required this.chat, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _chatInputKey = GlobalKey<ChatInputWidgetState>();
  final TextEditingController _messageController = TextEditingController();
  late AutoScrollController _scrollController;
  UserModel? _companion;
  Product? _product;
  int? _editingIndex;
  int? _selectedMessageIndex;
  bool _selectedMessageIsMe = false;
  bool _isImageSelectionMode = false;
  static const int maxImagesPerMessage = 10;
  int? _selectedImageMessageIndex;
  Set<int> _selectedImageIndices = {};
  List<String> _currentImagePaths = [];
  bool _isAdmin = false;
  bool _editingHasImages = false;
  bool _isUploadingImages = false;
  late ChatProvider _chatProvider;
  bool _aiMode = true;
  bool _humanRequested = false;
  String? _assignedOperatorId;
  bool _initialScrollDone = false;
  DateTime? _lastReadTimestamp;
  bool _showUnreadDivider = false;
  int? _unreadDividerMessageIndex;
  bool _applyingInitialState = false;
  bool _needRefresh = false;
  bool _isHeaderReady = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatProvider = context.read<ChatProvider>();
    _chatProvider.addListener(_onChatUpdated);
    _scrollController = AutoScrollController();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      _isAdmin = auth.isAdmin;
      final user = auth.currentUser;
      if (user != null) {
        await context.read<ChatProvider>().openChat(widget.chat.id);
      }
      NotificationService().cancelChatNotification(widget.chat.id);
      _connectivitySubscription =
          context.read<ConnectivityService>().onConnectivityChanged.listen((results) {
            final hasInternet = results.any((r) => r != ConnectivityResult.none);
            if (hasInternet && _needRefresh && mounted) {
              _refreshChat();
            }
          });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatProvider.removeListener(_onChatUpdated);
    _connectivitySubscription?.cancel();
    _chatProvider.closeChat(widget.chat.id);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final companionId = widget.chat.user1Id == user.uid
        ? widget.chat.user2Id
        : widget.chat.user1Id;
    final authProvider = context.read<AuthProvider>();
    final companion = await authProvider.getUserById(companionId);
    if (!mounted) return;
    Product? product;
    if (widget.chat.productId != null) {
      try {
        product = await ProductService.getProductById(widget.chat.productId.toString());
      } catch (e) {
        debugPrint('Не удалось загрузить товар: $e');
      }
    }
    if (!mounted) return;
    setState(() {
      _companion = companion;
      _product = product;
    });
    await _preloadMessageImages();
  }

  Future<void> _preloadMessageImages() async {
    final chat = _chatProvider.getChatById(widget.chat.id);
    if (chat == null) return;
    for (final msg in chat.messages) {
      if (msg.images != null) {
        for (final key in msg.images!) {
          await StorageService.getDownloadUrl(key, cache: true);
        }
      }
    }
  }

  void _updateChatState() {
    final chat = _chatProvider.getChatById(widget.chat.id);
    if (chat != null) {
      setState(() {
        _aiMode = chat.aiMode;
        _humanRequested = chat.humanRequested;
        _assignedOperatorId = chat.assignedOperatorId;
      });
    }
  }

  Future<void> _refreshChat() async {
    _needRefresh = false;
    await _chatProvider.openChat(widget.chat.id);
    if (mounted) setState(() {});
  }

  void _showImageViewer(int messageIndex, int imageIndex) async {
    final chat = _chatProvider.getChatById(widget.chat.id);
    if (chat == null) return;
    final msg = chat.messages[messageIndex];
    if (msg.images == null || msg.images!.isEmpty) return;
    final List<String> resolvedUrls = [];

    for (final imgPath in msg.images!) {
      if (imgPath.startsWith('http://') || imgPath.startsWith('https://')) {
        resolvedUrls.add(imgPath);
      } else {
        final file = File(imgPath);
        if (file.existsSync()) {
          resolvedUrls.add(imgPath);
        } else {
          final url = await StorageService.getDownloadUrl(imgPath, cache: true);
          resolvedUrls.add(url ?? imgPath);
        }
      }
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewer(
          imageUrls: resolvedUrls,
          initialIndex: imageIndex,
        ),
      ),
    );
  }

  void _onChatUpdated() {
    if (!mounted || _applyingInitialState) return;
    final chat = _chatProvider.getChatById(widget.chat.id);
    final user = context.read<AuthProvider>().currentUser;
    if (chat == null || user == null) return;

    _updateChatState();

    if (chat.messages.isNotEmpty && !_applyingInitialState) {
      final lastMsg = chat.messages.last;
      if (lastMsg.senderId != user.uid) {
        _chatProvider.markChatAsRead(widget.chat.id, user.uid);
      }
    }

    if (!_initialScrollDone) {
      _applyInitialReadState();
    } else {
      if (!_isUploadingImages) {
        _scrollToBottom();
      }
      if (chat.messages.isEmpty && mounted) {
        final connectivity = context.read<ConnectivityService>();
        if (!connectivity.hasInternet) {
          _needRefresh = true;
        }
      }
    }
  }

  void _applyInitialReadState() {
    if (!mounted || _applyingInitialState) return;
    _applyingInitialState = true;

    final chat = _chatProvider.getChatById(widget.chat.id);
    final user = context.read<AuthProvider>().currentUser;
    if (chat == null || user == null) {
      _applyingInitialState = false;
      return;
    }

    if (chat.messages.isEmpty) {
      setState(() {
        _isHeaderReady = true;
      });
      _applyingInitialState = false;
      return;
    }

    _lastReadTimestamp = _chatProvider.getLastReadTimestamp(widget.chat.id, user.uid);
    int? firstUnreadIndex;
    if (_lastReadTimestamp != null) {
      for (int i = 0; i < chat.messages.length; i++) {
        final msg = chat.messages[i];
        if (msg.senderId != user.uid && msg.timestamp.isAfter(_lastReadTimestamp!)) {
          firstUnreadIndex = i;
          break;
        }
      }
    }

    setState(() {
      if (firstUnreadIndex != null) {
        _showUnreadDivider = true;
        _unreadDividerMessageIndex = firstUnreadIndex;
      } else {
        _showUnreadDivider = false;
        _unreadDividerMessageIndex = null;
      }
      _isHeaderReady = true;
    });

    _chatProvider.markChatAsRead(widget.chat.id, user.uid);
    _applyingInitialState = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (firstUnreadIndex != null) {
        _scrollToMessage(firstUnreadIndex);
      } else if (chat.messages.isNotEmpty) {
        _scrollToMessage(chat.messages.length - 1);
      }
      _initialScrollDone = true;
    });
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients && _initialScrollDone) {
        _scrollToBottom();
      }
    });
  }

  Future<void> _scrollToMessage(int? index) async {
    if (index == null || !_scrollController.hasClients) return;
    await Future.delayed(const Duration(milliseconds: 100));
    int retries = 5;
    while (retries > 0 && !_scrollController.position.hasContentDimensions) {
      await Future.delayed(const Duration(milliseconds: 100));
      retries--;
    }
    await _scrollController.scrollToIndex(
      index,
      preferPosition: AutoScrollPosition.begin,
      duration: const Duration(milliseconds: 1),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _sendOrEditMessage() async {
    final text = _messageController.text.trim();
    final localPaths = _currentImagePaths.isNotEmpty
        ? List<String>.from(_currentImagePaths)
        : null;

    if (_editingIndex != null && text.isEmpty && (localPaths == null || localPaths.isEmpty)) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final provider = context.read<ChatProvider>();
    final bool isSupportChat = _companion != null &&
        ((_companion!.role == 'support' && user.role == 'user') ||
            (_companion!.role == 'user' && user.role == 'support'));
    final isCurrentUserSupport = user.role == 'support';
    final shouldUseAI = isSupportChat &&
        !isCurrentUserSupport &&
        _aiMode &&
        !_humanRequested &&
        _assignedOperatorId == null;

    if (!provider.isDeviceTimeAccurate) {
      if (mounted) {
        SnackBarCustom.show(context,
            message: 'Ошибка времени: проверьте настройки даты/времени на устройстве.');
      }
      return;
    }

    setState(() => _isUploadingImages = true);

    try {
      if (_editingIndex != null) {
        provider.editMessage(widget.chat.id, _editingIndex!, text, newImages: localPaths);
        _cancelEditing();
      } else if (shouldUseAI) {
        List<String>? cloudKeys;
        if (localPaths != null && localPaths.isNotEmpty) {
          cloudKeys = [];
          for (final path in localPaths) {
            final key = await StorageService.uploadChatImage(path);
            cloudKeys.add(key);
          }
        }
        final userClientId = DateTime.now().millisecondsSinceEpoch.toString();
        final userMessage = Message(
          senderId: user.uid,
          text: text,
          timestamp: DateTime.now(),
          images: cloudKeys,
          clientId: userClientId,
        );
        await provider.sendMessage(widget.chat.id, userMessage, clientId: userClientId);
        _messageController.clear();
        setState(() => _currentImagePaths.clear());

        final aiResponse = await AIAssistant.sendMessage(text);
        final botClientId = DateTime.now().millisecondsSinceEpoch.toString() + '_ai';
        final botMessage = Message(
          senderId: 'ai_assistant',
          text: aiResponse,
          timestamp: DateTime.now(),
          clientId: botClientId,
        );
        await provider.sendAIMessage(widget.chat.id, botMessage);

        if (AIAssistant.needsOperator(aiResponse) && !_humanRequested) {
          await provider.requestHumanOperator(widget.chat.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Оператор уведомлён, ожидайте ответа')),
            );
          }
        }
      } else {
        List<String>? cloudKeys;
        if (localPaths != null && localPaths.isNotEmpty) {
          cloudKeys = [];
          for (final path in localPaths) {
            final key = await StorageService.uploadChatImage(path);
            cloudKeys.add(key);
          }
        }
        final clientId = DateTime.now().millisecondsSinceEpoch.toString();
        final message = Message(
          senderId: user.uid,
          text: text,
          timestamp: DateTime.now(),
          images: cloudKeys,
          clientId: clientId,
        );
        await provider.sendMessage(widget.chat.id, message, clientId: clientId);
        _messageController.clear();
        setState(() => _currentImagePaths.clear());
        if (isCurrentUserSupport) {
          await provider.updateChatField(widget.chat.id, {'humanRequested': false});
          _updateChatState();
        }
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) SnackBarCustom.show(context, message: 'Ошибка отправки: $e');
    } finally {
      if (mounted) setState(() => _isUploadingImages = false);
    }
  }

  void _startEditing(int index, String currentText, List<String>? currentImages) {
    setState(() {
      _editingIndex = index;
      _messageController.text = currentText;
      _selectedMessageIndex = null;
      _editingHasImages = currentImages != null && currentImages.isNotEmpty;
    });
    _chatInputKey.currentState?.setInitialImages(currentImages ?? []);
  }

  void _cancelEditing() {
    setState(() {
      _editingIndex = null;
      _messageController.clear();
      _currentImagePaths.clear();
    });
    _chatInputKey.currentState?.setInitialImages([]);
  }

  void _deleteMessage(int index) {
    final chat = _chatProvider.getChatById(widget.chat.id);
    if (chat == null || index >= chat.messages.length) return;
    final msg = chat.messages[index];
    if (msg.images != null) {
      for (final key in msg.images!) {
        StorageService.deleteImage(key);
      }
    }
    _chatProvider.deleteMessage(widget.chat.id, index);
    if (_selectedMessageIndex == index) _deselectMessage();
  }

  void _copySelectedMessage() {
    if (_selectedMessageIndex == null) return;
    final chat = _chatProvider.getChatById(widget.chat.id);
    final messages = chat?.messages ?? [];
    if (_selectedMessageIndex! >= messages.length) return;
    final msg = messages[_selectedMessageIndex!];
    if (msg.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: msg.text));
    }
    _deselectMessage();
  }

  void _editSelectedMessage() {
    if (_selectedMessageIndex == null) return;
    final chat = _chatProvider.getChatById(widget.chat.id);
    final messages = chat?.messages ?? [];
    if (_selectedMessageIndex! >= messages.length) return;
    final msg = messages[_selectedMessageIndex!];
    _startEditing(_selectedMessageIndex!, msg.text, msg.images);
    _deselectMessage();
  }

  void _deleteSelectedMessage() {
    if (_selectedMessageIndex == null) return;
    _deleteMessage(_selectedMessageIndex!);
    _deselectMessage();
  }

  void _moderateSelectedMessage() {
    if (_selectedMessageIndex == null) return;
    _chatProvider.moderateDeleteMessage(widget.chat.id, _selectedMessageIndex!);
    _deselectMessage();
  }

  void _selectMessage(int index) {
    final chat = _chatProvider.getChatById(widget.chat.id);
    final messages = chat?.messages ?? [];
    if (index < 0 || index >= messages.length) return;
    setState(() {
      if (_selectedMessageIndex == index) {
        _deselectMessage();
        return;
      }
      _selectedMessageIndex = index;
      _selectedMessageIsMe = messages[index].senderId == context.read<AuthProvider>().currentUser?.uid;
      _editingIndex = null;
      _messageController.clear();
      _selectedImageMessageIndex = null;
      _selectedImageIndices = {};
      _isImageSelectionMode = false;
    });
  }

  void _deselectMessage() {
    setState(() {
      _selectedMessageIndex = null;
      _selectedMessageIsMe = false;
    });
  }

  void _selectImage(int messageIndex, int imageIndex) {
    setState(() {
      _selectedMessageIndex = null;
      _selectedMessageIsMe = false;
      if (!_isImageSelectionMode) {
        _isImageSelectionMode = true;
        _selectedImageMessageIndex = messageIndex;
        _selectedImageIndices = {imageIndex};
        return;
      }
      if (_selectedImageMessageIndex != messageIndex) {
        _selectedImageMessageIndex = messageIndex;
        _selectedImageIndices = {imageIndex};
        return;
      }
      if (_selectedImageIndices.contains(imageIndex)) {
        _selectedImageIndices.remove(imageIndex);
        if (_selectedImageIndices.isEmpty) {
          _selectedImageMessageIndex = null;
          _isImageSelectionMode = false;
        }
      } else {
        _selectedImageIndices.add(imageIndex);
      }
    });
  }

  void _deselectImages() {
    setState(() {
      _selectedImageMessageIndex = null;
      _selectedImageIndices = {};
      _isImageSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedImages() async {
    if (_selectedImageMessageIndex == null || _selectedImageIndices.isEmpty) return;
    final chat = context.read<ChatProvider>().getChatById(widget.chat.id);
    final messages = chat?.messages ?? [];
    if (_selectedImageMessageIndex! >= messages.length) return;

    final msg = messages[_selectedImageMessageIndex!];
    final currentImages = List<String>.from(msg.images ?? []);
    final sortedIndices = _selectedImageIndices.toList()..sort((a, b) => b.compareTo(a));
    for (final idx in sortedIndices) {
      if (idx < currentImages.length) {
        currentImages.removeAt(idx);
      }
    }
    if (currentImages.isEmpty && msg.text.isEmpty) {
      _deleteMessage(_selectedImageMessageIndex!);
      _deselectImages();
      return;
    }
    final chatId = widget.chat.id;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('timestamp', isEqualTo: msg.timestamp.toIso8601String())
        .where('senderId', isEqualTo: msg.senderId)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.update({
        'images': currentImages.isEmpty ? FieldValue.delete() : currentImages,
      });
      chat?.messages[_selectedImageMessageIndex!] = Message(
        senderId: msg.senderId,
        text: msg.text,
        timestamp: msg.timestamp,
        images: currentImages.isEmpty ? null : currentImages,
        edited: msg.edited,
      );
      setState(() {});
    }
    _deselectImages();
  }

  Future<void> _replaceSelectedImages() async {
    if (_selectedImageMessageIndex == null || _selectedImageIndices.isEmpty) return;
    final picker = ImagePicker();
    final messenger = ScaffoldMessenger.of(context);
    final pickedFiles = await picker.pickMultiImage();
    if (!mounted) return;
    if (pickedFiles.isEmpty) return;

    final chat = context.read<ChatProvider>().getChatById(widget.chat.id);
    final messages = chat?.messages ?? [];
    if (_selectedImageMessageIndex! >= messages.length) return;
    final msg = messages[_selectedImageMessageIndex!];
    final currentImages = List<String>.from(msg.images ?? []);
    final newPaths = <String>[];
    for (final file in pickedFiles) {
      final savedPath = await _saveImagePermanently(file.path);
      newPaths.add(savedPath);
    }
    final sortedIndices = _selectedImageIndices.toList()..sort((a, b) => b.compareTo(a));
    for (final idx in sortedIndices) {
      if (idx < currentImages.length) {
        currentImages.removeAt(idx);
      }
    }
    if (currentImages.length + newPaths.length > maxImagesPerMessage) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Нельзя добавить больше $maxImagesPerMessage фото в одно сообщение')),
      );
      return;
    }
    currentImages.addAll(newPaths);
    if (!mounted) return;
    context.read<ChatProvider>().editMessage(
      widget.chat.id,
      _selectedImageMessageIndex!,
      msg.text,
      newImages: currentImages.isEmpty ? null : currentImages,
    );
    _deselectImages();
  }

  Future<String> _saveImagePermanently(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final chatDir = Directory('${directory.path}/chat_images');
      if (!await chatDir.exists()) {
        await chatDir.create(recursive: true);
      }
      final fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${chatDir.path}/$fileName');
      await File(sourcePath).copy(savedImage.path);
      return savedImage.path;
    } catch (e) {
      return sourcePath;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final chat = _chatProvider.getChatById(widget.chat.id);
    final messages = chat?.messages ?? widget.chat.messages;
    final bool canWrite = (chat?.user1Id == user?.uid || chat?.user2Id == user?.uid);
    final companion = _companion;
    final currentUser = user;
    final bool isSupportChat = companion != null && currentUser != null &&
        ((companion.role == 'support' && currentUser.role == 'user') ||
            (companion.role == 'user' && currentUser.role == 'support'));
    final bool isParticipant = chat?.user1Id == user?.uid || chat?.user2Id == user?.uid;
    final bool isCurrentUserSupport = user?.role == 'support';
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          ChatHeader(
            key: ValueKey(_companion?.uid ?? 'no_companion'),
            chat: widget.chat,
            companion: _companion,
            product: _product,
            isImageSelectionMode: _selectedImageMessageIndex != null,
            selectedImageMessageIndex: _selectedImageMessageIndex,
            selectedMessageIndex: _selectedMessageIndex,
            selectedImageIndices: _selectedImageIndices,
            isAdmin: _isAdmin,
            selectedMessageIsMe: _selectedMessageIsMe,
            onDeselectMessage: _deselectMessage,
            onCopyMessage: _copySelectedMessage,
            onEditMessage: _editSelectedMessage,
            onDeleteMessage: _deleteSelectedMessage,
            onModerateMessage: _moderateSelectedMessage,
            onDeselectImages: _deselectImages,
            onReplaceImages: _replaceSelectedImages,
            onDeleteSelectedImages: _deleteSelectedImages,
            isReady: _isHeaderReady,
            onSellerTap: () {
              if (_companion != null) {
                context.read<BottomNavProvider>().showUserProfile(_companion!.uid);
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            isSupportChat: isSupportChat,
            isCurrentUserSupport: isCurrentUserSupport,
            isParticipant: isParticipant,
            aiMode: _aiMode,
            humanRequested: _humanRequested,
            assignedOperatorId: _assignedOperatorId,
            onRequestHumanOperator: () async {
              await _chatProvider.requestHumanOperator(widget.chat.id);
            },
            onToggleAiMode: () async {
              await _chatProvider.toggleAiMode(widget.chat.id, !_aiMode);
            },
          ),
          if (_humanRequested && !isCurrentUserSupport)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Оператор скоро ответит...',
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                  ),
                ],
              ),
            ),
          Expanded(
            child: messages.isEmpty
                ? Center(
              child: Text(
                'Нет сообщений. Начните общение!',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
            )
                : ChatMessageList(
              messages: messages,
              scrollController: _scrollController,
              currentUser: user,
              companion: _companion,
              selectedMessageIndex: _selectedMessageIndex,
              selectedImageMessageIndex: _selectedImageMessageIndex,
              selectedImageIndices: _selectedImageIndices,
              showUnreadDivider: _showUnreadDivider,
              unreadDividerMessageIndex: _unreadDividerMessageIndex,
              isImageSelectionMode: _isImageSelectionMode,
              onSelectMessage: _selectMessage,
              onSelectImage: _selectImage,
              onImageLongPress: (msgIdx, imgIdx) => _selectImage(msgIdx, imgIdx),
              isCurrentUserSupport: isCurrentUserSupport,
              onImageTapGallery: _showImageViewer,
            ),
          ),
          if (canWrite)
            ChatInputWidget(
              key: _chatInputKey,
              messageController: _messageController,
              isEditing: _editingIndex != null,
              hasImagesInOriginalMessage: _editingHasImages,
              isUploading: _isUploadingImages,
              onSend: _sendOrEditMessage,
              onCancelEdit: _cancelEditing,
              onImagesSelected: (paths) => setState(() => _currentImagePaths = paths),
              onReplaceImage: (_editingIndex != null)
                  ? (imgIdx) async {
                final messenger = ScaffoldMessenger.of(context);
                if (imgIdx == -1) {
                  final picker = ImagePicker();
                  final pickedFiles = await picker.pickMultiImage();
                  if (!mounted) return;
                  if (pickedFiles.isEmpty) return;
                  final newPaths = <String>[];
                  final remaining = maxImagesPerMessage;
                  int added = 0;
                  for (int i = 0; i < pickedFiles.length && added < remaining; i++) {
                    final key = await StorageService.uploadChatImage(
                        await _saveImagePermanently(pickedFiles[i].path));
                    newPaths.add(key);
                    added++;
                  }
                  if (added < pickedFiles.length && mounted) {
                    messenger.showSnackBar(SnackBar(content: Text(
                        'Добавлено $added из ${pickedFiles.length}. Лимит 10 фото.')));
                  }
                  _chatInputKey.currentState?.setInitialImages(newPaths);
                  setState(() => _currentImagePaths = newPaths);
                  return;
                } else {
                  final picker = ImagePicker();
                  final pickedFiles = await picker.pickMultiImage();
                  if (!mounted) return;
                  if (pickedFiles.isEmpty) return;
                  final newPaths = <String>[];
                  final remaining = maxImagesPerMessage - (_currentImagePaths.length - 1);
                  int added = 0;
                  for (int i = 0; i < pickedFiles.length && added < remaining; i++) {
                    final key = await StorageService.uploadChatImage(
                        await _saveImagePermanently(pickedFiles[i].path));
                    newPaths.add(key);
                    added++;
                  }
                  if (added < pickedFiles.length && mounted) {
                    messenger.showSnackBar(SnackBar(content: Text(
                        'Добавлено $added из ${pickedFiles.length}. Лимит 10 фото.')));
                  }
                  _chatInputKey.currentState?.replaceImageAt(imgIdx, newPaths);
                }
              }
                  : null,
            ),
        ],
      ),
    );
  }
}