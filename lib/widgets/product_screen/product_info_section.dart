import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/lease_request.dart';
import '../../models/activeLease.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/LeaseRequestProvider.dart';
import '../../provider/ReviewsProvider.dart';
import '../../provider/activeLeasesProvider.dart';
import '../../utils/colors.dart';
import '../../utils/snackbar_custom.dart';
import '../../pages/chat_screen.dart';
import '../../provider/chat_provider.dart';

class ProductInfoSection extends StatefulWidget {
  final Product product;

  const ProductInfoSection({required this.product, super.key});

  @override
  State<ProductInfoSection> createState() => _ProductInfoSectionState();
}

class _ProductInfoSectionState extends State<ProductInfoSection> {
  bool _isRequested = false;

  void _onRentPressed() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || _isRequested) return;

    final request = LeaseRequest(
      id: DateTime.now().millisecondsSinceEpoch,
      productId: widget.product.id,
      productName: widget.product.name,
      pricePerDay: widget.product.price,
      totalDays: 1,
      requesterId: user.id,
      requesterFirstName: user.firstName,
      requesterLastName: user.lastName,
      requesterAvatarPath: user.avatarPath,
      ownerId: widget.product.ownerId,
      images: widget.product.images,
    );
    context.read<LeaseRequestProvider>().addRequest(request);

    final leasesProvider = context.read<ActiveLeasesProvider>();
    leasesProvider.addActiveLease(ActiveLease(
      productId: widget.product.id,
      name: widget.product.name,
      pricePerDay: widget.product.price,
      startDate: null,
      totalDays: 1,
      userId: user.id,
      ownerId: widget.product.ownerId,
      userFirstName: user.firstName,
      userLastName: user.lastName,
      userAvatarPath: user.avatarPath,
      status: LeaseStatus.pending,
    ));

    setState(() {
      _isRequested = true;
    });

    SnackBarCustom.show(context, message: 'Запрос на аренду отправлен');
  }

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewsProvider>()
        .getReviewsForProduct(widget.product.id);
    final double avgRating = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    final String ratingText = reviews.isEmpty
        ? '—'
        : avgRating.toStringAsFixed(1);

    final product = widget.product;
    final priceUnit = product.isPricePerHour ? 'за час' : 'за день';
    final currentUser = context.read<AuthProvider>().currentUser;
    final isOwner = currentUser?.id == product.ownerId;

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
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                      color: AppColors.oliveGray),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${product.price} ₽',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.oliveGray),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.star, size: 25, color: AppColors.yellowSchoolBus),
              const SizedBox(width: 3),
              Text(
                ratingText,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: AppColors.oliveGray),
              ),
              if (reviews.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  '(${reviews.length})',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.oliveGray.withOpacity(0.5)),
                ),
              ],
              const Spacer(),
              Text(
                priceUnit,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: AppColors.oliveGray.withOpacity(0.5)),
              ),
            ],
          ),
          if (!isOwner) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isRequested ? null : _onRentPressed,
              icon: _isRequested
                  ? const Icon(Icons.check_circle,
                  size: 20, color: AppColors.spaceCream)
                  : const SizedBox.shrink(),
              label: Text(
                _isRequested ? 'Запрос отправлен' : 'Арендовать',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRequested
                    ? AppColors.oliveGray.withOpacity(0.4)
                    : AppColors.copper,
                foregroundColor: AppColors.spaceCream,
                padding: const EdgeInsets.symmetric(vertical: 5),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final user = context.read<AuthProvider>().currentUser;
                if (user == null) return;
                final authProvider = context.read<AuthProvider>();
                final owner =
                await authProvider.getUserById(product.ownerId);
                final productImage = product.images.isNotEmpty
                    ? product.images[0]
                    : null;
                final chat = context.read<ChatProvider>().getOrCreateChat(
                  user.id,
                  product.ownerId,
                  productId: product.id,
                  productName: product.name,
                  productImage: productImage,
                  companionName: owner != null
                      ? '${owner.firstName} ${owner.lastName}'
                      : 'Продавец',
                  companionAvatar: owner?.avatarPath,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChatScreen(chat: chat)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.whiteAntique,
                foregroundColor: AppColors.oliveGray,
                side: BorderSide(
                    color: AppColors.oliveGray.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(vertical: 5),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Написать продавцу',
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ]
        ],
      ),
    );
  }
}