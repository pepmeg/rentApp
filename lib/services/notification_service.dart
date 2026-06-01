import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  final Map<String, List<_ChatMessage>> _chatMessages = {};

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
          enableVibration: true,
          playSound: true,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'lease_requests',
          'Запросы аренды',
          description: 'Уведомления о новых запросах аренды',
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
    String? senderName,
    String? senderAvatarPath,
    String? productImage,
  }) async {
    final notificationId = chatId.hashCode;

    final messages = _chatMessages.putIfAbsent(chatId, () => []);
    messages.add(_ChatMessage(
      text: messageText,
      timestamp: DateTime.now(),
      sender: senderName ?? chatTitle,
    ));
    if (messages.length > 10) {
      messages.removeAt(0);
    }

    final sender = Person(
      name: senderName ?? chatTitle,
    );
    final notificationMessages = messages.map((m) {
      return Message(
        m.text,
        m.timestamp,
        sender,
      );
    }).toList();

    final style = MessagingStyleInformation(
      sender,
      messages: notificationMessages,
      groupConversation: true,
      conversationTitle: chatTitle,
    );

    final androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Сообщения',
      channelDescription: 'Уведомления о новых сообщениях',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: style,
      groupKey: 'app_rent_chats_summary',
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

  void clearChatMessages(String chatId) {
    _chatMessages.remove(chatId);
  }

  Future<void> showLeaseNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'lease_requests',
      'Запросы аренды',
      channelDescription: 'Уведомления о новых запросах аренды',
      importance: Importance.high,
      priority: Priority.high,
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    _chatMessages.clear();
  }

  Future<void> cancelChatNotification(String chatId) async {
    await _plugin.cancel(id: chatId.hashCode);
    _chatMessages.remove(chatId);
  }

  Future<void> scheduleReviewReminder({
    required String productId,
    required String productName,
    required DateTime scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'review_reminder',
      'Напоминания об отзывах',
      channelDescription: 'Напомнить оставить отзыв на товар',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.zonedSchedule(
        id: productId.hashCode,
        title: 'Оцените аренду',
        body: 'Как вам товар "$productName"? Оставьте отзыв!',
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'product_$productId',
      );
    } catch (e) {
      debugPrint('Ошибка планирования уведомления: $e');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    if (payload == 'notifications') {
      navigatorKey.currentState?.pushNamed('/notifications');
    } else if (payload == 'active_leases') {
      navigatorKey.currentState?.pushNamed('/active_leases');
    } else if (payload == 'cart') {
      navigatorKey.currentState?.pushNamed('/cart');
    } else if (payload.startsWith('product_')) {
      final productId = payload.substring(8);
      navigatorKey.currentState?.pushNamed('/product', arguments: productId);
    } else {
      clearChatMessages(payload);
      navigatorKey.currentState?.pushNamed('/chat', arguments: payload);
    }
  }
}

class _ChatMessage {
  final String text;
  final DateTime timestamp;
  final String sender;
  _ChatMessage({required this.text, required this.timestamp, required this.sender});
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();