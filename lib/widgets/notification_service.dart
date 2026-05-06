import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class _MessageData {
  final String text;
  final int timestampMs;
  final String authorName;
  const _MessageData(this.text, this.timestampMs, this.authorName);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  final Map<String, List<_MessageData>> _pendingMessages = {};

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'chat_messages',
          'Сообщения',
          description: 'Уведомления о новых сообщениях',
          importance: Importance.high,
        ),
      );
      await androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    _initialized = true;
  }

  Future<void> showChatNotification({
    required String chatId,
    required String chatTitle,
    required String messageText,
    required int unreadCount,
    String? payload,
  }) async {
    final int notificationId = chatId.hashCode;

    _pendingMessages.putIfAbsent(chatId, () => []);
    _pendingMessages[chatId]!.add(
      _MessageData(
        messageText,
        DateTime.now().millisecondsSinceEpoch,
        chatTitle,
      ),
    );

    if (_pendingMessages[chatId]!.length > 10) {
      _pendingMessages[chatId] = _pendingMessages[chatId]!
          .sublist(_pendingMessages[chatId]!.length - 10);
    }

    final List<Message> styleMessages = _pendingMessages[chatId]!.map((msg) {
      return Message(
        msg.text,
        DateTime.fromMillisecondsSinceEpoch(msg.timestampMs),
        Person(name: msg.authorName, bot: false),
      );
    }).toList();

    final androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Сообщения',
      channelDescription: 'Уведомления о новых сообщениях',
      importance: Importance.high,
      priority: Priority.high,
      number: unreadCount,
      styleInformation: MessagingStyleInformation(
        Person(name: chatTitle, bot: false),
        groupConversation: false,
        conversationTitle: chatTitle,
        messages: styleMessages,
      ),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: unreadCount,
      threadIdentifier: chatId,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: notificationId,
      title: chatTitle,
      body: messageText,
      notificationDetails: details,
      payload: payload ?? chatId,
    );
  }

  Future<void> cancelChatNotification(String chatId) async {
    await _plugin.cancel(id: chatId.hashCode);
    _pendingMessages.remove(chatId);
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      navigatorKey.currentState?.pushNamed('/chat', arguments: payload);
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();