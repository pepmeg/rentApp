import 'package:intl/intl.dart';

String formatLastMessageTime(DateTime utcTime) {
  final moscow = utcTime.add(const Duration(hours: 3));
  final nowUtc = DateTime.now().toUtc();
  final nowMoscow = nowUtc.add(const Duration(hours: 3));
  final today = DateTime(nowMoscow.year, nowMoscow.month, nowMoscow.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final messageDate = DateTime(moscow.year, moscow.month, moscow.day);

  if (messageDate == today) {
    return DateFormat('HH:mm').format(moscow);
  } else if (messageDate == yesterday) {
    return 'Вчера';
  } else if (utcTime.year == nowUtc.year) {
    return DateFormat('d MMMM', 'ru').format(moscow);
  } else {
    return DateFormat('d MMMM yyyy', 'ru').format(moscow);
  }
}

String formatLocalMessageTime(DateTime localTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final messageDate = DateTime(localTime.year, localTime.month, localTime.day);

  if (messageDate == today) {
    return DateFormat('HH:mm').format(localTime);
  } else if (messageDate == yesterday) {
    return 'Вчера';
  } else if (localTime.year == now.year) {
    return DateFormat('d MMMM', 'ru').format(localTime);
  } else {
    return DateFormat('d MMMM yyyy', 'ru').format(localTime);
  }
}