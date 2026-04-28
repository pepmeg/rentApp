import 'dart:io';
import 'package:AppRent/pages/productScreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../data/product_data.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../provider/AuthProvider.dart';
import '../provider/bottom_nav_provider.dart';
import '../provider/chat_provider.dart';
import '../utils/colors.dart';
import '../widgets/chat/chat_input_widget.dart';
import '../widgets/chat/chat_message_widget.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  const ChatScreen({required this.chat, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatInputKey = GlobalKey<ChatInputWidgetState>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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
    if (mounted) setState(() { _companion = companion; _product = product; });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectMessage(int index) {
    final chat = context.read<ChatProvider>().getChatById(widget.chat.id);
    final messages = chat?.messages ?? [];
    if (index < 0 || index >= messages.length) return;

    setState(() {
      if (_selectedMessageIndex == index) {
        _deselectMessage();
        return;
      }
      _selectedMessageIndex = index;
      _selectedMessageIsMe = messages[index].senderId == context.read<AuthProvider>().currentUser?.id;
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
    context.read<ChatProvider>().editMessage(
      widget.chat.id,
      _selectedImageMessageIndex!,
      msg.text,
      newImages: currentImages.isEmpty ? null : currentImages,
    );
    _deselectImages();
  }

  Future<void> _replaceSelectedImages() async {
    if (_selectedImageMessageIndex == null || _selectedImageIndices.isEmpty) return;

    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles == null || pickedFiles.isEmpty) return;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Нельзя добавить больше $maxImagesPerMessage фото в одно сообщение')),
      );
      return;
    }
    currentImages.addAll(newPaths);

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

  void _copySelectedMessage() {
    if (_selectedMessageIndex == null) return;
    final chat = context.read<ChatProvider>().getChatById(widget.chat.id);
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
    final chat = context.read<ChatProvider>().getChatById(widget.chat.id);
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

  void _sendOrEditMessage() {
    final text = _messageController.text.trim();
    final List<String>? images = _currentImagePaths.isNotEmpty ? List.from(_currentImagePaths) : null;
    if (_editingIndex == null && text.isEmpty && (images == null || images.isEmpty)) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final provider = context.read<ChatProvider>();
    if (_editingIndex != null) {
      if (text.isEmpty && (images == null || images.isEmpty)) return;

      provider.editMessage(
        widget.chat.id,
        _editingIndex!,
        text,
        newImages: images,
      );
      _cancelEditing();
    } else {
      final message = Message(
        senderId: user.id,
        text: text,
        timestamp: DateTime.now(),
        images: images,
      );
      provider.sendMessage(widget.chat.id, message);
      _messageController.clear();
      setState(() => _currentImagePaths.clear());
    }
    _scrollToBottom();
  }

  void _startEditing(int index, String currentText, List<String>? currentImages) {
    setState(() {
      _editingIndex = index;
      _messageController.text = currentText;
      _selectedMessageIndex = null;
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
    context.read<ChatProvider>().deleteMessage(widget.chat.id, index);
    if (_selectedMessageIndex == index) _deselectMessage();
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
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Сегодня';
    } else if (dateToCheck == yesterday) {
      return 'Вчера';
    }
    return DateFormat('d MMMM', 'ru').format(date);
  }

  bool _shouldShowDate(int index, List<Message> messages) {
    if (index == 0) return true;
    final prev = messages[index - 1].timestamp;
    final curr = messages[index].timestamp;
    return prev.day != curr.day || prev.month != curr.month || prev.year != curr.year;
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 40, bottom: 10),
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
          if (_selectedImageMessageIndex != null)
            _buildImageActionBar()
          else if (_selectedMessageIndex != null)
            _buildActionBar()
          else
            _buildSellerRow(context),
          if (_product != null) ...[
            const SizedBox(height: 8),
            Divider(color: AppColors.oliveGray.withOpacity(0.2), height: 1),
            const SizedBox(height: 8),
            _buildProductRow(context),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close, size: 24, color: AppColors.oliveGray),
          onPressed: _deselectMessage,
          constraints: const BoxConstraints(),
        ),
        const Spacer(),
        if (_selectedMessageIsMe) ...[
          IconButton(
            icon: const Icon(Icons.edit, size: 24, color: AppColors.oliveGray),
            onPressed: _editSelectedMessage,
          ),
        ],
        IconButton(
          icon: const Icon(Icons.copy, size: 24, color: AppColors.oliveGray),
          onPressed: _copySelectedMessage,
        ),
        if (_selectedMessageIsMe) ...[
          IconButton(
            icon: const Icon(Icons.delete, size: 24, color:  AppColors.oliveGray),
            onPressed: _deleteSelectedMessage,
          ),
        ],
      ],
    );
  }

  Widget _buildImageActionBar() {
    final count = _selectedImageIndices.length;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close, size: 24, color: AppColors.oliveGray),
          onPressed: _deselectImages,
          constraints: const BoxConstraints(),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Text('$count', style: const TextStyle(fontSize: 16, color: AppColors.oliveGray)),
        ],
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.swap_horiz, size: 24, color: AppColors.oliveGray),
          onPressed: _replaceSelectedImages,
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 24, color:  AppColors.oliveGray),
          onPressed: _deleteSelectedImages,
        ),
      ],
    );
  }

  Widget _buildSellerRow(BuildContext context) {
    return GestureDetector(
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
                ? (_companion!.avatarPath!.startsWith('assets/')
                ? AssetImage(_companion!.avatarPath!)
                : FileImage(File(_companion!.avatarPath!)))
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.oliveGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _product != null ? 'По товару' : 'Чат',
                  style: TextStyle(fontSize: 13, color: AppColors.oliveGray.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductScreen(product: _product!)),
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
                  Text(_product!.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.oliveGray),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${_product!.price} ₽',
                      style: TextStyle(fontSize: 13, color: AppColors.oliveGray.withOpacity(0.6))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final chat = context.watch<ChatProvider>().getChatById(widget.chat.id);
    final messages = chat?.messages ?? widget.chat.messages;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: messages.isEmpty
                ? Center(
                child: Text('Нет сообщений. Начните общение!',
                    style: TextStyle(color: AppColors.oliveGray.withOpacity(0.5))))
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg.senderId == user?.id;
                final showAvatar = index == 0 || messages[index - 1].senderId != msg.senderId;
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
                final selectedImageSet = (_selectedImageMessageIndex == index)
                    ? _selectedImageIndices
                    : <int>{};

                return ChatMessageWidget(
                  message: msg,
                  isMe: isMe,
                  showAvatar: showAvatar,
                  showDate: showDate,
                  showTime: showTime,
                  dateText: _formatDate(msg.timestamp),
                  timeText: timeString,
                  companion: _companion,
                  isSelected: index == _selectedMessageIndex,
                  onLongPress: () => _selectMessage(index),
                  onImageLongPress: (imgIdx) => _selectImage(index, imgIdx),
                  onImageTap: (imgIdx) {
                    if (_isImageSelectionMode) {
                      _selectImage(index, imgIdx);
                    }
                  },
                  selectedImageIndices: selectedImageSet,
                );
              },
            ),
          ),
          ChatInputWidget(
            key: _chatInputKey,
            messageController: _messageController,
            isEditing: _editingIndex != null,
            onSend: _sendOrEditMessage,
            onCancelEdit: _cancelEditing,
            onImagesSelected: (paths) => setState(() => _currentImagePaths = paths),
            onReplaceImage: (_editingIndex != null) ? (imgIdx) async {
              if (imgIdx == -1) {
                final picker = ImagePicker();
                final pickedFiles = await picker.pickMultiImage();
                if (pickedFiles == null || pickedFiles.isEmpty) return;

                final newPaths = <String>[];
                final remaining = maxImagesPerMessage;
                int added = 0;
                for (int i = 0; i < pickedFiles.length && added < remaining; i++) {
                  final savedPath = await _saveImagePermanently(pickedFiles[i].path);
                  newPaths.add(savedPath);
                  added++;
                }
                if (added < pickedFiles.length) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Добавлено $added из ${pickedFiles.length}. Лимит 10 фото.')),
                  );
                }
                _chatInputKey.currentState?.setInitialImages(newPaths);
                setState(() => _currentImagePaths = newPaths);
                return;
              }
              final picker = ImagePicker();
              final pickedFiles = await picker.pickMultiImage();
              if (pickedFiles == null || pickedFiles.isEmpty) return;
              final newPaths = <String>[];
              final remaining = maxImagesPerMessage - (_currentImagePaths.length - 1);
              int added = 0;
              for (int i = 0; i < pickedFiles.length && added < remaining; i++) {
                final savedPath = await _saveImagePermanently(pickedFiles[i].path);
                newPaths.add(savedPath);
                added++;
              }
              if (added < pickedFiles.length) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Добавлено $added из ${pickedFiles.length}. Лимит 10 фото.')),
                );
              }
              _chatInputKey.currentState?.replaceImageAt(imgIdx, newPaths);
            } : null,
          ),
        ],
      ),
    );
  }
}