import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ChatProvider extends ChangeNotifier {
  final Map<String, Chat> _chats = {};
  final Map<String, DateTime> _lastReadTimestamps = {};
  static const String _chatsKey = 'chats';
  static const String _lastReadKey = 'chat_last_read';

  ChatProvider() {
    loadFromPrefs();
  }

  List<Chat> getChatsForUser(int userId) {
    return _chats.values.where((c) => c.user1Id == userId || c.user2Id == userId).toList();
  }

  Chat getOrCreateChat(int user1Id, int user2Id, {
    int? productId,
    String? productName,
    String? productImage,
    String? companionName,
    String? companionAvatar,
  }) {
    final id = _createChatId(user1Id, user2Id, productId);
    if (_chats.containsKey(id)) {
      return _chats[id]!;
    }
    final chat = Chat(
      id: id,
      user1Id: user1Id,
      user2Id: user2Id,
      productId: productId,
      productName: productName,
      productImage: productImage,
      companionName: companionName,
      companionAvatar: companionAvatar,
    );
    _chats[id] = chat;
    notifyListeners();
    _saveToPrefs();
    return chat;
  }

  void sendMessage(String chatId, Message message) {
    final chat = _chats[chatId];
    if (chat != null) {
      chat.messages.add(message);
      notifyListeners();
      _saveToPrefs();
    }
  }

  String _createChatId(int user1Id, int user2Id, int? productId) {
    final ids = [user1Id, user2Id]..sort();
    return '${ids[0]}_${ids[1]}_${productId ?? 0}';
  }

  Chat? getChatById(String id) {
    return _chats[id];
  }

  void markChatAsRead(String chatId, int userId) {
    final chat = _chats[chatId];
    if (chat == null || chat.messages.isEmpty) return;

    final lastMessageTime = chat.messages.last.timestamp;
    final key = '${chatId}_$userId';
    _lastReadTimestamps[key] = lastMessageTime;
    notifyListeners();
    _saveLastReadToPrefs();
  }

  bool isChatUnread(String chatId, int userId) {
    final chat = _chats[chatId];
    if (chat == null || chat.messages.isEmpty) return false;

    final lastMessage = chat.messages.last;
    if (lastMessage.senderId == userId) return false;

    final key = '${chatId}_$userId';
    final lastRead = _lastReadTimestamps[key];
    return lastRead == null || lastMessage.timestamp.isAfter(lastRead);
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = _chats.map((key, chat) => MapEntry(key, chat.toJson()));
    final jsonString = jsonEncode(jsonMap);
    await prefs.setString(_chatsKey, jsonString);
  }

  Future<void> _saveLastReadToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = _lastReadTimestamps.map((key, value) => MapEntry(key, value.toIso8601String()));
    await prefs.setString(_lastReadKey, jsonEncode(jsonMap));
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString(_chatsKey);
    if (jsonString != null) {
      try {
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        _chats.clear();
        jsonMap.forEach((key, value) {
          _chats[key] = Chat.fromJson(value);
        });
      } catch (e) {
        print('Ошибка загрузки чатов: $e');
      }
    }

    final lastReadString = prefs.getString(_lastReadKey);
    if (lastReadString != null) {
      try {
        final jsonMap = jsonDecode(lastReadString) as Map<String, dynamic>;
        _lastReadTimestamps.clear();
        jsonMap.forEach((key, value) {
          _lastReadTimestamps[key] = DateTime.parse(value);
        });
      } catch (e) {
        print('Ошибка загрузки lastRead: $e');
      }
    }

    notifyListeners();
  }

  void editMessage(String chatId, int index, String newText, {List<String>? newImages}) {
    final chat = _chats[chatId];
    if (chat == null || index < 0 || index >= chat.messages.length) return;
    final old = chat.messages[index];
    chat.messages[index] = Message(
      senderId: old.senderId,
      text: newText,
      timestamp: old.timestamp,
      images: newImages ?? old.images,
      edited: true,
    );
    notifyListeners();
    _saveToPrefs();
  }

  void deleteMessage(String chatId, int index) {
    final chat = _chats[chatId];
    if (chat == null || index < 0 || index >= chat.messages.length) return;
    chat.messages.removeAt(index);
    notifyListeners();
    _saveToPrefs();
  }

  void deleteChats(Set<String> chatIds) {
    for (final id in chatIds) {
      _chats.remove(id);
      _lastReadTimestamps.removeWhere((key, value) => key.startsWith('${id}_'));
    }
    notifyListeners();
    _saveToPrefs();
    _saveLastReadToPrefs();
  }

  void deleteChatsForUser(int userId) {
    _chats.removeWhere((key, chat) => chat.user1Id == userId || chat.user2Id == userId);
    _lastReadTimestamps.removeWhere((key, value) => key.endsWith('_$userId'));
    notifyListeners();
    _saveToPrefs();
    _saveLastReadToPrefs();
  }
}