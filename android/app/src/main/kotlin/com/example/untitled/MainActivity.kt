package com.example.untitled

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.Person
import androidx.core.graphics.drawable.IconCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL_ID = "chat_messages"
    private val SUMMARY_GROUP_KEY = "app_rent_chats_summary"
    private val NOTIFICATION_SERVICE_CHANNEL = "com.example.untitled/notifications"

    private val chatTitles = mutableMapOf<String, String>()
    private val chatUnreadCount = mutableMapOf<String, Int>()
    private val messagesCache = mutableMapOf<String, MutableList<NotificationCompat.MessagingStyle.Message>>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_SERVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showChatNotification" -> {
                        val chatId = call.argument<String>("chatId") ?: return@setMethodCallHandler
                        val chatTitle = call.argument<String>("chatTitle") ?: ""
                        val messageText = call.argument<String>("messageText") ?: ""
                        val unreadCount = call.argument<Int>("unreadCount") ?: 1
                        val payload = call.argument<String>("payload")
                        val lastMessagesData = call.argument<List<Map<String, Any>>>("lastMessagesData")
                        val companionAvatar = call.argument<String>("companionAvatar")
                        val productImage = call.argument<String>("productImage")
                        chatTitles[chatId] = chatTitle
                        showChatNotification(chatId, chatTitle, messageText, unreadCount, payload, lastMessagesData, companionAvatar, productImage)
                        result.success(null)
                    }
                    "cancelChatNotification" -> {
                        val chatId = call.argument<String>("chatId") ?: return@setMethodCallHandler
                        chatTitles.remove(chatId)
                        cancelChatNotification(chatId)
                        result.success(null)
                    }
                    "cancelAllNotifications" -> {
                        cancelAllNotifications()
                        chatTitles.clear()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Сообщения",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Уведомления о новых сообщениях"
                setShowBadge(true)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun loadBitmapOrNull(path: String?) = try {
        if (path != null && File(path).exists()) BitmapFactory.decodeFile(path) else null
    } catch (e: Exception) { null }

    private fun showChatNotification(
        chatId: String,
        chatTitle: String,
        messageText: String,
        unreadCount: Int,
        payload: String?,
        lastMessagesData: List<Map<String, Any>>? = null,
        companionAvatar: String? = null,
        productImage: String? = null
    ) {
        val notificationId = chatId.hashCode()
        val bitmap = loadBitmapOrNull(companionAvatar) ?: loadBitmapOrNull(productImage)
        val senderBuilder = Person.Builder().setName(chatTitle)
        if (bitmap != null) {
            senderBuilder.setIcon(IconCompat.createWithBitmap(bitmap))
        }
        val sender = senderBuilder.build()

        val messages = mutableListOf<NotificationCompat.MessagingStyle.Message>()

        if (lastMessagesData != null) {
            messagesCache.remove(chatId)
            lastMessagesData.forEach { data ->
                val text = data["text"] as? String ?: ""
                val timestampMs = when (val ts = data["timestampMs"]) {
                    is Long -> ts
                    is Int -> ts.toLong()
                    is Double -> ts.toLong()
                    else -> System.currentTimeMillis()
                }
                messages.add(NotificationCompat.MessagingStyle.Message(text, timestampMs, sender))
            }
        } else {
            messages.add(NotificationCompat.MessagingStyle.Message(messageText, System.currentTimeMillis(), sender))
        }

        val limitedMessages = messages.takeLast(10)
        messagesCache[chatId] = limitedMessages.toMutableList()

        val style = NotificationCompat.MessagingStyle(sender)
            .setConversationTitle(chatTitle)
        limitedMessages.forEach { style.addMessage(it) }

        var smallIconResId = resources.getIdentifier("ic_launcher", "mipmap", packageName)
        if (smallIconResId == 0) {
            smallIconResId = android.R.drawable.ic_dialog_email
        }

        val tapIntent = PendingIntent.getActivity(
            this, notificationId,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val notificationManager = NotificationManagerCompat.from(this)

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(smallIconResId)
            .setStyle(style)
            .setContentTitle(chatTitle)
            .setContentText(messageText)
            .setNumber(unreadCount)
            .setGroup(SUMMARY_GROUP_KEY)
            .setGroupAlertBehavior(NotificationCompat.GROUP_ALERT_CHILDREN)
            .setContentIntent(tapIntent)
            .setAutoCancel(true)

        if (bitmap != null) {
            builder.setLargeIcon(bitmap)
        }

        notificationManager.notify(notificationId, builder.build())

        chatUnreadCount[chatId] = unreadCount
        updateSummaryNotification(notificationManager, smallIconResId)
    }

    private fun updateSummaryNotification(notificationManager: NotificationManagerCompat, smallIconResId: Int) {
        val totalUnread = chatUnreadCount.values.sum()
        val chatCount = chatUnreadCount.size

        val contentText = if (chatCount == 1) {
            "$totalUnread новых сообщений"
        } else {
            "Сообщения в $chatCount чатах"
        }

        val inboxStyle = NotificationCompat.InboxStyle()
        inboxStyle.setBigContentTitle("Новые сообщения")
        chatUnreadCount.forEach { (chatId, count) ->
            val name = chatTitles[chatId] ?: chatId
            inboxStyle.addLine("$name: $count непрочитанных")
        }

        val summaryNotification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(smallIconResId)
            .setGroup(SUMMARY_GROUP_KEY)
            .setGroupSummary(true)
            .setContentTitle("Новые сообщения")
            .setContentText(contentText)
            .setStyle(inboxStyle)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(SUMMARY_GROUP_KEY.hashCode(), summaryNotification)
    }

    private fun cancelChatNotification(chatId: String) {
        val notificationManager = NotificationManagerCompat.from(this)
        notificationManager.cancel(chatId.hashCode())
        messagesCache.remove(chatId)
        chatUnreadCount.remove(chatId)

        if (chatUnreadCount.isEmpty()) {
            notificationManager.cancel(SUMMARY_GROUP_KEY.hashCode())
        } else {
            val smallIconResId = resources.getIdentifier("ic_launcher", "mipmap", packageName)
            updateSummaryNotification(notificationManager, smallIconResId)
        }
    }

    private fun cancelAllNotifications() {
        val notificationManager = NotificationManagerCompat.from(this)
        notificationManager.cancelAll()
        messagesCache.clear()
        chatUnreadCount.clear()
    }
}