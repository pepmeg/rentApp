import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static const MethodChannel _channel = MethodChannel('com.example.untitled/notifications');

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
    List<Map<String, dynamic>>? lastMessagesData,
    String? companionAvatar,
    String? productImage,
  }) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('showChatNotification', {
          'chatId': chatId,
          'chatTitle': chatTitle,
          'messageText': messageText,
          'unreadCount': unreadCount,
          'payload': payload ?? chatId,
          if (lastMessagesData != null) 'lastMessagesData': lastMessagesData,
          if (companionAvatar != null) 'companionAvatar': companionAvatar,
          if (productImage != null) 'productImage': productImage,
        });
      } catch (e) { print('Error: $e'); }
    } else {
      final int notificationId = chatId.hashCode;
      const androidDetails = AndroidNotificationDetails(
        'chat_messages',
        'Сообщения',
        channelDescription: 'Уведомления о новых сообщениях',
        importance: Importance.high,
        priority: Priority.high,
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
  }

  Future<void> cancelAllNotifications() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('cancelAllNotifications');
      } catch (_) {}
    } else {
      await _plugin.cancelAll();
    }
  }

  Future<void> cancelChatNotification(String chatId) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('cancelChatNotification', {'chatId': chatId});
      } catch (_) {}
    } else {
      await _plugin.cancel(id: chatId.hashCode);
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      navigatorKey.currentState?.pushNamed('/chat', arguments: payload);
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();