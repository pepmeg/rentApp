import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/lease_request.dart';
import '../../models/activeLease.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/LeaseRequestProvider.dart';
import '../../provider/activeLeasesProvider.dart';
import '../../provider/ReviewsProvider.dart';
import '../../theme/theme_data.dart';
import '../../utils/const.dart';
import '../../utils/snackbar_custom.dart';
import '../../pages/chat_screen.dart';
import '../../provider/chat_provider.dart';
import '../app_button.dart';

class ProductInfoSection extends StatelessWidget {
  final Product product;
  const ProductInfoSection({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final leaseRequestProvider = context.watch<LeaseRequestProvider>();
    final activeLeasesProvider = context.watch<ActiveLeasesProvider>();
    final theme = Theme.of(context);

    final isRequested = user != null && leaseRequestProvider.hasPendingOrAcceptedRequest(user.uid, product.id);
    final isActiveLease = user != null && activeLeasesProvider.leases.any((lease) =>
    lease.productId == product.id &&
        lease.userId == user.uid &&
        (lease.status == LeaseStatus.active || lease.status == LeaseStatus.pendingCompletion));
    final bool canRent = !isRequested && !isActiveLease;
    final String buttonText = isActiveLease
        ? 'В аренде'
        : (isRequested ? 'Запрос отправлен' : 'Арендовать');
    final reviews = context.watch<ReviewsProvider>().getReviewsForProduct(product.id);
    final double avgRating = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    final String ratingText = reviews.isEmpty ? '—' : avgRating.toStringAsFixed(1);
    final isOwner = user?.uid == product.ownerId;
    final isUser = user?.role == 'user';
    final isAvailable = product.moderationStatus == 'active';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${product.price} ₽',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.star, size: 25, color: AppTheme.starColor),
              const SizedBox(width: 3),
              Text(
                ratingText,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (reviews.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  '(${reviews.length})',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                product.isPricePerHour ? 'за час' : 'за день',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          if (!isOwner && isUser && isAvailable) ...[
            const SizedBox(height: 10),
            if (user?.blocked == true)
              Button(
                text: 'Аккаунт заблокирован',
                onPressed: null,
                size: ButtonSize.large,
              )
            else
              Button(
                text: buttonText,
                onPressed: canRent ? () => _onRentPressed(context) : null,
                size: ButtonSize.large,
              ),
            const SizedBox(height: 10),
            Button(
              text: 'Написать продавцу',
              onPressed: () => _startChat(context),
              variant: ButtonVariant.outlined,
              size: ButtonSize.large,
            ),
          ],
        ],
      ),
    );
  }

  void _onRentPressed(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final leaseProvider = context.read<LeaseRequestProvider>();
    if (leaseProvider.hasPendingOrAcceptedRequest(user.uid, product.id)) {
      SnackBarCustom.show(context, message: 'Вы уже отправляли запрос на этот товар');
      return;
    }
    if (user.blockedUntil != null && user.blockedUntil!.isAfter(DateTime.now())) {
      final blockedUntilFormatted = DateFormat('dd.MM.yyyy').format(user.blockedUntil!);
      SnackBarCustom.show(
        context,
        message: 'Вы заблокированы до $blockedUntilFormatted за неоплату аренд. Попробуйте позже.',
      );
      return;
    }
    if (user.unpaidLeaseCount >= AppConst.maxUnpaidLeaseCount) {
      SnackBarCustom.show(
        context,
        message: 'У вас слишком много неоплаченных аренд. Оплатите или обратитесь в поддержку.',
        actionLabel: 'Корзина',
        onAction: () => Navigator.pushNamed(context, '/cart'),
      );
      return;
    }
    final request = LeaseRequest(
      firestoreDocId: '',
      productId: product.id,
      productName: product.name,
      pricePerDay: product.price,
      totalDays: 1,
      requesterId: user.uid,
      requesterFirstName: user.firstName,
      requesterLastName: user.lastName,
      requesterAvatarPath: user.avatarUrl,
      ownerId: product.ownerId,
      images: product.images,
      isHourly: product.isPricePerHour,
      requesterRating: user.rating,
    );
    leaseProvider.addRequest(
      request,
      leasesProvider: context.read<ActiveLeasesProvider>(),
    );
    SnackBarCustom.show(context, message: 'Запрос на аренду отправлен');
  }

  void _startChat(BuildContext context) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>();
    final owner = await authProvider.getUserById(product.ownerId);
    final productImage = product.images.isNotEmpty ? product.images[0] : null;
    final chat = await chatProvider.getOrCreateChat(
      user.uid,
      product.ownerId,
      productId: int.tryParse(product.id) ?? 0,
      productName: product.name,
      productImage: productImage,
      companionName: owner != null ? '${owner.firstName} ${owner.lastName}' : 'Продавец',
      companionAvatar: owner?.avatarUrl,
    );
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
    }
  }
}