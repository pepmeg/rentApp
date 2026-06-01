import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ntp_dart/models/accurate_time.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/messager_model/chat.dart';
import '../models/messager_model/message.dart';
import '../services/notification_service.dart';

class ChatProvider extends ChangeNotifier with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Chat> _chats = {};
  final Map<String, DateTime> _lastReadTimestamps = {};
  final Map<String, StreamSubscription<QuerySnapshot>> _messagesSubscriptions = {};
  bool _wasMissedNotificationShown = false;
  bool _isAppInForeground = true;
  StreamSubscription<QuerySnapshot>? _chatsSubscription;
  static const _prefsKeyOffset = 'server_time_offset_ms';
  bool _serverTimeOffsetReady = false;
  Duration _serverTimeOffset = Duration.zero;
  static const String _cachePrefix = 'chat_msgs_';
  StreamSubscription<QuerySnapshot>? _allChatsSubscription;
  static const String _chatListCacheKey = 'cached_chats_v2';
  bool _isLoadingChats = false;
  bool get isLoadingChats => _isLoadingChats;

  ChatProvider() {
    WidgetsBinding.instance.addObserver(this);
    syncServerTimeOffset();
  }

  DateTime? getLastReadTimestamp(String chatId, String userId) {
    return _lastReadTimestamps['${chatId}_$userId'];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _cacheChats(String userId, List<Chat> chats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = chats.map((c) {
        final json = c.toJson();
        json['companionRole'] = c.companionRole;
        return json;
      }).toList();
      await prefs.setString('${_chatListCacheKey}_$userId', jsonEncode(data));
    } catch (e) {
      debugPrint('Ошибка сохранения кеша чатов: $e');
    }
  }

  Future<List<Chat>?> _loadCachedChats(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('${_chatListCacheKey}_$userId');
      if (jsonString == null) return null;
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((e) {
        final map = e as Map<String, dynamic>;
        final chat = Chat.fromJson(map);
        chat.companionRole = map['companionRole'] as String?;
        return chat;
      }).toList();
    } catch (e) {
      debugPrint('Ошибка загрузки кеша чатов: $e');
      return null;
    }
  }

  Future<void> updateChatField(String chatId, Map<String, dynamic> updates) async {
    await _firestore.collection('chats').doc(chatId).update(updates);
    final chat = _chats[chatId];
    if (chat != null) {
      final updatedChat = Chat(
        id: chat.id,
        user1Id: chat.user1Id,
        user2Id: chat.user2Id,
        productId: chat.productId,
        productName: chat.productName,
        productImage: chat.productImage,
        companionName: chat.companionName,
        companionAvatar: chat.companionAvatar,
        messages: chat.messages,
        aiMode: updates['aiMode'] as bool? ?? chat.aiMode,
        humanRequested: updates['humanRequested'] as bool? ?? chat.humanRequested,
        assignedOperatorId: updates['assignedOperatorId'] as String? ?? chat.assignedOperatorId,
      );
      _chats[chatId] = updatedChat;
      notifyListeners();
    }
  }

  Future<void> requestHumanOperator(String chatId) async {
    await updateChatField(chatId, {'humanRequested': true, 'aiMode': false});
  }

  Future<void> toggleAiMode(String chatId, bool enable) async {
    await updateChatField(chatId, {'aiMode': enable});
    if (!enable) {
      await updateChatField(chatId, {'assignedOperatorId': null, 'humanRequested': false});
    }
  }

  Future<void> assignOperatorToChat(String chatId, String operatorId) async {
    await updateChatField(chatId, {
      'assignedOperatorId': operatorId,
      'aiMode': false,
      'humanRequested': false,
    });
  }

  Future<void> openChat(String chatId) async {
    if (_messagesSubscriptions.containsKey(chatId)) return;

    final chat = _chats[chatId];
    if (chat == null) return;

    if (chat.messages.isEmpty) {
      final cached = await _loadCachedMessages(chatId);
      if (cached != null && cached.isNotEmpty) {
        chat.messages.clear();
        chat.messages.addAll(cached);
        notifyListeners();
      }
    }

    try {
      await _loadMessagesForChat(chat, limit: 25);
      notifyListeners();
    } catch (e) {
      debugPrint('Не удалось загрузить свежие сообщения для чата $chatId: $e');
    }

    DocumentSnapshot? lastDoc;
    try {
      lastDoc = await _getLastMessageDoc(chatId);
    } catch (e) {
      debugPrint('Не удалось получить lastDoc для подписки: $e');
      return;
    }

    final query = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false);

    final subscription = (lastDoc != null ? query.startAfterDocument(lastDoc) : query)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          final newMsg = Message.fromJson(data);

          if (newMsg.clientId != null) {
            final localIndex = chat.messages.indexWhere((m) => m.clientId == newMsg.clientId);
            if (localIndex != -1) {
              chat.messages[localIndex] = newMsg;
            } else {
              chat.messages.add(newMsg);
            }
          } else {
            final localIndex = chat.messages.indexWhere((m) =>
            m.senderId == newMsg.senderId &&
                m.text == newMsg.text &&
                (m.timestamp.difference(newMsg.timestamp).inSeconds.abs() < 10));
            if (localIndex != -1) {
              chat.messages[localIndex] = newMsg;
            } else {
              chat.messages.add(newMsg);
            }
          }
          notifyListeners();
        }
      }
    });
    _messagesSubscriptions[chatId] = subscription;
  }

  void closeChat(String chatId) {
    _messagesSubscriptions[chatId]?.cancel();
    _messagesSubscriptions.remove(chatId);
  }

  void listenToAllChats() {
    _allChatsSubscription?.cancel();
    _allChatsSubscription = _firestore
        .collection('chats')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final chat = Chat.fromJson(change.doc.data()!);
          if (!_chats.containsKey(chat.id)) {
            _chats[chat.id] = chat;
            _loadMessagesForChat(chat);
          }
        } else if (change.type == DocumentChangeType.modified) {
          final updatedChat = Chat.fromJson(change.doc.data()!);
          _chats[updatedChat.id] = updatedChat;
        } else if (change.type == DocumentChangeType.removed) {
          _chats.remove(change.doc.id);
        }
      }
      notifyListeners();
    });
  }

  void cancelAllChatsSubscription() {
    _allChatsSubscription?.cancel();
    _allChatsSubscription = null;
  }

  Future<DocumentSnapshot?> _getLastMessageDoc(String chatId) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
  }

  Future<void> _cacheMessages(String chatId, List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final toCache = messages.length > 25
        ? messages.sublist(messages.length - 25)
        : messages;
    final List<Map<String, dynamic>> jsonList =
    toCache.map((m) => m.toJson()).toList();
    await prefs.setString('$_cachePrefix$chatId', jsonEncode(jsonList));
  }

  Future<void> loadChatsForUser(String userId) async {
    if (_isLoadingChats) return;
    _isLoadingChats = true;
    notifyListeners();
    final cached = await _loadCachedChats(userId);
    if (cached != null && cached.isNotEmpty) {
      for (final chat in cached) {
        if (!_chats.containsKey(chat.id)) {
          _chats[chat.id] = chat;
          final cachedMessages = await _loadCachedMessages(chat.id);
          if (cachedMessages != null && cachedMessages.isNotEmpty) {
            chat.messages.clear();
            chat.messages.addAll(cachedMessages);
          }
        }
      }
      _isLoadingChats = false;
      notifyListeners();
    }
    List<Chat> freshChats = [];
    try {
      final snapshot = await _firestore
          .collection('chats')
          .where(Filter.or(
        Filter('user1Id', isEqualTo: userId),
        Filter('user2Id', isEqualTo: userId),
      ))
          .get();

      for (final doc in snapshot.docs) {
        final chat = Chat.fromJson(doc.data());
        freshChats.add(chat);
        _chats[chat.id] = chat;
        await _syncLastReadFromFirestore(chat.id, userId);
        await _loadMessagesForChat(chat);
      }
      await _loadCompanionRolesForChats(freshChats, userId);

      final freshIds = freshChats.map((c) => c.id).toSet();
      final toRemove = _chats.keys.where((id) => !freshIds.contains(id)).toList();
      for (final id in toRemove) {
        _chats.remove(id);
        _lastReadTimestamps.removeWhere((key, value) => key.startsWith('${id}_'));
      }
      await _cacheChats(userId, freshChats);
    } catch (e) {
      debugPrint('Ошибка загрузки чатов из Firestore: $e');
    }
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final role = userDoc.data()?['role'] as String?;
      String? companionUid;

      if (role == 'user') {
        companionUid = await getSupportUid();
      } else if (role == 'support') {
        companionUid = await getAdminUid();
      } else if (role == 'admin') {
        companionUid = await getSupportUid();
      }

      if (companionUid != null) {
        final chatId = _createChatId(userId, companionUid, null);
        if (!_chats.containsKey(chatId)) {
          final chat = await getOrCreateChat(userId, companionUid);
          if (chat != null) {
            _chats[chatId] = chat;
            freshChats.add(chat);
            await _cacheChats(userId, freshChats);
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка создания чата с поддержкой: $e');
    }
    _isLoadingChats = false;
    notifyListeners();
  }

  Future<String?> getSupportUid() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'support')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.first.id : null;
  }

  Future<String?> getAdminUid() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.first.id : null;
  }

  Future<void> _loadCompanionRolesForChats(List<Chat> chats, String currentUserId) async {
    final Set<String> companionIds = {};
    for (final chat in chats) {
      final companionId = chat.user1Id == currentUserId ? chat.user2Id : chat.user1Id;
      companionIds.add(companionId);
    }
    if (companionIds.isEmpty) return;

    final usersSnapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: companionIds.toList())
        .get();

    final Map<String, String> roleMap = {};
    for (final doc in usersSnapshot.docs) {
      roleMap[doc.id] = doc.data()['role'] as String? ?? 'user';
    }

    for (final chat in chats) {
      final companionId = chat.user1Id == currentUserId ? chat.user2Id : chat.user1Id;
      chat.companionRole = roleMap[companionId] ?? 'user';
    }
  }

  List<Chat> getChatsForUser(String userId) {
    return _chats.values
        .where((c) => c.user1Id == userId || c.user2Id == userId)
        .toList();
  }

  Future<void> _syncLastReadFromFirestore(String chatId, String userId) async {
    final doc = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('readStatus')
        .doc(userId)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      DateTime lastRead;
      final timestamp = data['timestamp'];
      if (timestamp is Timestamp) {
        lastRead = timestamp.toDate().toUtc();
      } else if (timestamp is String) {
        lastRead = DateTime.parse(timestamp).toUtc();
      } else {
        lastRead = DateTime.now().toUtc();
      }
      _lastReadTimestamps['${chatId}_$userId'] = lastRead;
      notifyListeners();
    }
  }

  List<Chat> getAllChats() => _chats.values.toList();

  Chat? getChatById(String id) => _chats[id];

  String _createChatId(String user1Id, String user2Id, int? productId) {
    final ids = [user1Id, user2Id]..sort();
    return '${ids[0]}_${ids[1]}_${productId ?? 0}';
  }

  Future<Chat> getOrCreateChat(
      String user1Id,
      String user2Id, {
        int? productId,
        String? productName,
        String? productImage,
        String? companionName,
        String? companionAvatar,
      }) async {
    final id = _createChatId(user1Id, user2Id, productId);
    if (_chats.containsKey(id)) return _chats[id]!;

    String getNameForUser(String uid) {
      if (uid == '0') return 'Поддержка';
      if (uid == '999') return 'Администратор';
      return companionName ?? 'Пользователь';
    }

    final resolvedCompanionName = companionName ?? getNameForUser(user2Id);
    final resolvedCompanionAvatar = companionAvatar ?? (user2Id == '0' ? null : null);

    final doc = await _firestore.collection('chats').doc(id).get();
    if (doc.exists) {
      final raw = doc.data();
      if (raw != null) {
        final chat = Chat.fromJson(raw);
        _chats[id] = chat;
        await _loadMessagesForChat(chat);
        notifyListeners();
        return chat;
      }
    }

    final chat = Chat(
      id: id,
      user1Id: user1Id,
      user2Id: user2Id,
      productId: productId,
      productName: productName,
      productImage: productImage,
      companionName: resolvedCompanionName,
      companionAvatar: resolvedCompanionAvatar,
    );
    _chats[id] = chat;
    await _firestore.collection('chats').doc(id).set(chat.toJson());
    notifyListeners();
    return chat;
  }

  Future<void> _loadMessagesForChat(Chat chat, {int limit = 25}) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chat.id)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .limitToLast(limit)
          .get();
      final List<Message> freshMessages = snapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();
      final freshClientIds = freshMessages
          .where((m) => m.clientId != null)
          .map((m) => m.clientId!)
          .toSet();
      chat.messages.removeWhere(
              (local) => local.clientId != null && freshClientIds.contains(local.clientId));
      chat.messages.clear();
      chat.messages.addAll(freshMessages);
      chat.messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      await _cacheMessages(chat.id, chat.messages);
    } catch (e) {
      debugPrint('Ошибка загрузки сообщений из Firestore для чата ${chat.id}: $e');
      rethrow;
    }
  }

  Future<void> sendMessage(String chatId, Message message, {String? clientId}) async {
    final chat = _chats[chatId];
    if (chat == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final isBlocked = userDoc.data()?['blocked'] == true;
      if (isBlocked) {
        final isSupport = await _isSupportChat(chatId, currentUser.uid);
        if (!isSupport) {
          throw Exception('Ваш аккаунт заблокирован. Вы можете общаться только с поддержкой.');
        }
      }
    }

    if (isDeviceTimeAccurate) {
      final localMsg = Message(
        senderId: message.senderId,
        text: message.text,
        timestamp: DateTime.now().toUtc().add(_serverTimeOffset),
        images: message.images,
        clientId: clientId,
      );
      chat.messages.add(localMsg);
      notifyListeners();
    }
    final data = {
      'senderId': message.senderId,
      'text': message.text,
      'timestamp': FieldValue.serverTimestamp(),
      'images': message.images,
      'edited': message.edited,
      'moderated': message.moderated,
      if (clientId != null) 'clientId': clientId,
    };
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(data);
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': {
        'text': message.text,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': message.senderId,
      },
    });
    if (message.senderId != 'ai_assistant') {
      markChatAsRead(chatId, message.senderId);
    }
  }

  Future<bool> _isSupportChat(String chatId, String currentUserId) async {
    final chat = _chats[chatId];
    if (chat == null) return false;
    final otherId = chat.user1Id == currentUserId ? chat.user2Id : chat.user1Id;
    final otherUser = await _firestore.collection('users').doc(otherId).get();
    final role = otherUser.data()?['role'] as String?;
    return role == 'support' || role == 'admin';
  }

  Future<void> sendAIMessage(String chatId, Message message) async {
    final chat = _chats[chatId];
    if (chat == null) return;

    final data = {
      'senderId': message.senderId,
      'text': message.text,
      'timestamp': FieldValue.serverTimestamp(),
      'images': message.images,
      'edited': message.edited,
      'moderated': message.moderated,
      if (message.clientId != null) 'clientId': message.clientId,
    };

    await _firestore.collection('chats').doc(chatId).collection('messages').add(data);

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': {
        'text': message.text,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': message.senderId,
      },
    });
  }

  Future<void> editMessage(String chatId, int index, String newText, {List<String>? newImages}) async {
    final chat = _chats[chatId];
    if (chat == null || index < 0 || index >= chat.messages.length) return;
    final oldMsg = chat.messages[index];

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final isBlocked = userDoc.data()?['blocked'] == true;
      if (isBlocked && oldMsg.senderId == currentUser.uid) {
        final isSupport = await _isSupportChat(chatId, currentUser.uid);
        if (!isSupport) {
          throw Exception('Ваш аккаунт заблокирован. Вы не можете редактировать сообщения.');
        }
      }
    }

    chat.messages[index] = Message(
      senderId: oldMsg.senderId,
      text: newText,
      timestamp: oldMsg.timestamp,
      images: newImages ?? oldMsg.images,
      edited: true,
      moderated: oldMsg.moderated,
      clientId: oldMsg.clientId,
    );
    notifyListeners();

    final querySnapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('timestamp', isEqualTo: oldMsg.timestamp.toIso8601String())
        .where('senderId', isEqualTo: oldMsg.senderId)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.update({
        'text': newText,
        'images': newImages,
        'edited': true,
      });
    }
  }

  Future<void> deleteMessage(String chatId, int index) async {
    final chat = _chats[chatId];
    if (chat == null || index < 0 || index >= chat.messages.length) return;
    final msg = chat.messages[index];

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final isBlocked = userDoc.data()?['blocked'] == true;
      if (isBlocked && msg.senderId == currentUser.uid) {
        final isSupport = await _isSupportChat(chatId, currentUser.uid);
        if (!isSupport) {
          throw Exception('Ваш аккаунт заблокирован. Вы не можете удалять сообщения.');
        }
      }
    }

    chat.messages.removeAt(index);
    notifyListeners();

    final querySnapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('timestamp', isEqualTo: msg.timestamp.toIso8601String())
        .where('senderId', isEqualTo: msg.senderId)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.delete();
    }
  }

  Future<void> moderateDeleteMessage(String chatId, int index) async {
    final chat = _chats[chatId];
    if (chat == null || index < 0 || index >= chat.messages.length) return;
    final oldMsg = chat.messages[index];
    chat.messages[index] = Message(
      senderId: oldMsg.senderId,
      text: '',
      timestamp: oldMsg.timestamp,
      images: null,
      edited: true,
      moderated: true,
      clientId: oldMsg.clientId,
    );
    notifyListeners();

    final querySnapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('timestamp', isEqualTo: oldMsg.timestamp.toIso8601String())
        .where('senderId', isEqualTo: oldMsg.senderId)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.update({
        'text': '',
        'images': null,
        'edited': true,
        'moderated': true,
      });
    }
  }

  Future<void> syncServerTimeOffset() async {
    try {
      final accurateUtc = await AccurateTime.now(isUtc: true);
      final localNowUtc = DateTime.now().toUtc();
      _serverTimeOffset = accurateUtc.difference(localNowUtc);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyOffset, _serverTimeOffset.inMilliseconds);
    } catch (e) {
      debugPrint('NTP sync failed, loading cached offset: $e');
      final prefs = await SharedPreferences.getInstance();
      final cachedMs = prefs.getInt(_prefsKeyOffset) ?? 0;
      _serverTimeOffset = Duration(milliseconds: cachedMs);
    } finally {
      _serverTimeOffsetReady = true;
      notifyListeners();
    }
  }

  Future<void> deleteChats(Set<String> chatIds) async {
    final idsToDelete = Set<String>.from(chatIds);
    final batch = _firestore.batch();
    for (final chatId in idsToDelete) {
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      final readStatusSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('readStatus')
          .get();
      for (final doc in readStatusSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestore.collection('chats').doc(chatId));
    }

    try {
      await batch.commit();
      for (final chatId in idsToDelete) {
        _chats.remove(chatId);
        _lastReadTimestamps.removeWhere((key, value) => key.startsWith('${chatId}_'));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка удаления чатов: $e');
    }
  }

  bool get isDeviceTimeAccurate {
    if (!_serverTimeOffsetReady) return false;
    return _serverTimeOffset.abs().inMinutes < 5;
  }

  Future<void> deleteChatsForUser(String userId) async {
    final snapshot = await _firestore
        .collection('chats')
        .where(Filter.or(
      Filter('user1Id', isEqualTo: userId),
      Filter('user2Id', isEqualTo: userId),
    ))
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final chatId = doc.id;
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();
      for (final msgDoc in messagesSnapshot.docs) {
        batch.delete(msgDoc.reference);
      }
      final readStatusSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('readStatus')
          .get();
      for (final readDoc in readStatusSnapshot.docs) {
        batch.delete(readDoc.reference);
      }
      batch.delete(doc.reference);
    }

    try {
      await batch.commit();
      for (final doc in snapshot.docs) {
        _chats.remove(doc.id);
        _lastReadTimestamps.removeWhere((key, value) => key.startsWith('${doc.id}_'));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка удаления чатов пользователя: $e');
    }
  }

  void clearReadTimestampsForUser(String userId) {
    _lastReadTimestamps.removeWhere((key, value) => key.endsWith('_$userId'));
    notifyListeners();
  }

  bool _isMarkingAsRead = false;

  Future<void> markChatAsRead(String chatId, String userId) async {
    if (_isMarkingAsRead) return;
    _isMarkingAsRead = true;
    try {
      final chat = _chats[chatId];
      if (chat == null) {
        debugPrint('Чат $chatId не найден в _chats');
        return;
      }
      if (chat.user1Id != userId && chat.user2Id != userId) {
        debugPrint('Пользователь $userId не участник чата $chatId');
        return;
      }
      if (chat.messages.isEmpty) return;
      final nowUtc = DateTime.now().toUtc();
      _lastReadTimestamps['${chatId}_$userId'] = nowUtc;
      notifyListeners();

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('readStatus')
          .doc(userId)
          .set({'timestamp': FieldValue.serverTimestamp()});

      NotificationService().clearChatMessages(chatId);
    } finally {
      _isMarkingAsRead = false;
    }
  }

  int unreadMessageCount(String chatId, String userId) {
    final chat = _chats[chatId];
    if (chat == null || chat.messages.isEmpty) return 0;
    final lastRead = _lastReadTimestamps['${chatId}_$userId'];
    if (lastRead == null) {
      return chat.messages.where((m) => m.senderId != userId).length;
    }
    return chat.messages
        .where((m) => m.senderId != userId && m.timestamp.isAfter(lastRead))
        .length;
  }

  bool isChatUnread(String chatId, String userId) {
    final chat = _chats[chatId];
    if (chat == null || chat.messages.isEmpty) return false;
    final lastMsg = chat.messages.last;
    if (lastMsg.senderId == userId) return false;
    final lastRead = _lastReadTimestamps['${chatId}_$userId'];
    return lastRead == null || lastMsg.timestamp.isAfter(lastRead);
  }

  int unreadChatsCount(String userId) {
    return _chats.values
        .where((c) => c.user1Id == userId || c.user2Id == userId)
        .where((c) => isChatUnread(c.id, userId))
        .length;
  }

  void clearMissedNotifications() {
    NotificationService().cancelAllNotifications();
  }

  void notifyMissedMessages(String userId) {
    if (_wasMissedNotificationShown) return;

    final unreadChats = getChatsForUser(userId)
        .where((c) => isChatUnread(c.id, userId))
        .toList();

    if (unreadChats.isEmpty) return;
    if (unreadChats.length == 1) {
      final chat = unreadChats.first;
      final lastMsg = chat.messages.isNotEmpty ? chat.messages.last : null;
      final text = lastMsg?.text.isNotEmpty == true ? lastMsg!.text : '[Фото]';
      NotificationService().showChatNotification(
        chatId: chat.id,
        chatTitle: chat.companionName ?? 'Чат',
        messageText: text,
        unreadCount: 1,
        payload: chat.id,
      );
    } else {
      final totalUnread = unreadChats.fold<int>(0, (sum, c) => sum + unreadMessageCount(c.id, userId));
      NotificationService().showLeaseNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: 'Новые сообщения',
        body: 'У вас $totalUnread непрочитанных сообщений в ${unreadChats.length} чатах',
      );
    }

    _wasMissedNotificationShown = true;
  }

  void resetMissedNotificationFlag() {
    _wasMissedNotificationShown = false;
  }

  void listenForNewMessages(String userId) {
    _chatsSubscription?.cancel();
    _chatsSubscription = _firestore
        .collection('chats')
        .where(Filter.or(
      Filter('user1Id', isEqualTo: userId),
      Filter('user2Id', isEqualTo: userId),
    ))
        .snapshots()
        .listen((snapshot) {
      for (final docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.modified) {
          final data = docChange.doc.data();
          final lastMessage = data?['lastMessage'] as Map<String, dynamic>?;
          if (lastMessage == null) continue;
          final senderId = lastMessage['senderId'] as String?;
          final text = lastMessage['text'] as String? ?? '';
          final timestampField = lastMessage['timestamp'];

          if (senderId == null || timestampField == null) continue;
          DateTime msgTime;
          if (timestampField is Timestamp) {
            msgTime = timestampField.toDate().toUtc();
          } else if (timestampField is String) {
            msgTime = DateTime.parse(timestampField).toUtc();
          } else {
            continue;
          }

          if (senderId == userId) continue;
          final chatId = docChange.doc.id;
          final lastRead = _lastReadTimestamps['${chatId}_$userId'];
          if (lastRead != null && !msgTime.isAfter(lastRead)) continue;
          final chat = _chats[chatId];
          final chatTitle = chat?.companionName ?? 'Сообщение';
          final body = text.isNotEmpty ? text : '[Фото]';
          final unread = unreadMessageCount(chatId, userId);
          if (_isAppInForeground) {
            continue;
          }
          NotificationService().showChatNotification(
            chatId: chatId,
            chatTitle: chatTitle,
            messageText: body,
            unreadCount: unread,
            payload: chatId,
          );
        }
      }
      notifyListeners();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = (state == AppLifecycleState.resumed);
  }

  void cancelChatsSubscription() {
    _chatsSubscription?.cancel();
    _chatsSubscription = null;
  }

  Stream<int> unreadChatsCountStream(String userId) async* {
    yield unreadChatsCount(userId);
    await for (final _ in Stream<void>.periodic(const Duration(seconds: 1))) {
      yield unreadChatsCount(userId);
    }
  }

  Future<List<Message>?> _loadCachedMessages(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('$_cachePrefix$chatId');
    if (jsonString == null) return null;
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
}