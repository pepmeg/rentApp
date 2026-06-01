import 'dart:async';
import 'package:AppRent/widgets/plural.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../provider/AuthProvider.dart';
import '../provider/basket_provider.dart';
import '../services/notification_service.dart';
import '../utils/snackbar_custom.dart';
import 'product_image.dart';

class BasketCard extends StatefulWidget {
  final CartItem item;
  const BasketCard({required this.item, super.key});

  @override
  State<BasketCard> createState() => _BasketCardState();
}

class _BasketCardState extends State<BasketCard> {
  Timer? _timer;
  int _remainingHours = 0;
  bool _expiredHandled = false;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _updateRemainingTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _updateRemainingTime() async {
    final now = DateTime.now().toUtc();
    final expiry = widget.item.completedAt.add(const Duration(hours: 24));
    final remaining = expiry.difference(now);
    final hours = remaining.inHours;

    if (hours != _remainingHours) {
      setState(() => _remainingHours = hours);
    }

    if (hours < 0 && !_expiredHandled) {
      _expiredHandled = true;
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        await context.read<AuthProvider>().decrementRating(user.uid);
        await context.read<AuthProvider>().incrementUnpaidLeaseCount(user.uid);
        if (mounted) {
          SnackBarCustom.show(context, message: 'Время оплаты истекло. Рейтинг снижен.');
        }
      }
    }
    if (!widget.item.reminderSent && hours <= 2 && hours >= 0) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        await NotificationService().showLeaseNotification(
          id: widget.item.id.hashCode,
          title: 'Осталось 2 часа!',
          body: 'Оплатите товар "${widget.item.name}" в течение 2 часов, иначе вы будете заблокированы.',
          payload: 'cart',
        );
        await context.read<BasketProvider>().markReminderSent(user.uid, widget.item.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final bool isExpired = _remainingHours < 0;
    final int totalPrice = item.isHourly
        ? item.price * item.units
        : item.price * item.units + (item.price * item.extraHours / 24).round();
    final theme = Theme.of(context);

    String priceLabel;
    if (item.isHourly) {
      final hoursWord = Plural.hours(item.units);
      priceLabel = '${item.price} ₽ × ${item.units} $hoursWord = $totalPrice ₽';
    } else {
      String text = '${item.price} ₽/день';
      if (item.units > 0) text += ' × ${item.units} ${Plural.days(item.units)}';
      if (item.extraHours > 0) text += ' × ${item.extraHours} ${Plural.hours(item.extraHours)}';
      priceLabel = '$text = $totalPrice ₽';
    }

    final timeText = isExpired ? 'Просрочен' : 'Осталось: ${_remainingHours} ч.';
    final isWarning = !isExpired && _remainingHours <= 2;

    return Card(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: ProductImage(
                    images: item.images,
                    width: 80,
                    height: 80,
                    backgroundColor: theme.colorScheme.surface,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        priceLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: theme.dividerColor, height: 1),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isExpired
                    ? Colors.redAccent.withAlpha(30)
                    : (isWarning ? Colors.orangeAccent.withAlpha(30) : theme.primaryColor.withAlpha(25)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpired ? Icons.warning_amber_rounded : Icons.timer_outlined,
                    size: 18,
                    color: isExpired ? Colors.redAccent : (isWarning ? Colors.orangeAccent : theme.primaryColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isExpired ? Colors.redAccent : (isWarning ? Colors.orangeAccent : theme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}