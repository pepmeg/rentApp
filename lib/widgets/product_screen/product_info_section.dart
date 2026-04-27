import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/models/product.dart';
import 'package:untitled/models/lease_request.dart';
import 'package:untitled/models/activeLease.dart';
import 'package:untitled/provider/AuthProvider.dart';
import 'package:untitled/provider/LeaseRequestProvider.dart';
import 'package:untitled/provider/ReviewsProvider.dart';
import 'package:untitled/provider/activeLeasesProvider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/utils/snackbar_custom.dart';

import '../../pages/chat_screen.dart';
import '../../provider/chat_provider.dart';

class ProductInfoSection extends StatelessWidget {
  final Product product;

  const ProductInfoSection({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewsProvider>()
        .getReviewsForProduct(product.id);
    final double avgRating = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    final String ratingText = reviews.isEmpty
        ? '—'
        : avgRating.toStringAsFixed(1);

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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${product.price} ₽',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
              ),
              if (reviews.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  '(${reviews.length})',
                  style: TextStyle(fontSize: 14, color: AppColors.oliveGray.withOpacity(0.5)),
                ),
              ],
              const Spacer(),
              Text('за день', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray.withOpacity(0.5))),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              final user = context.read<AuthProvider>().currentUser;
              if (user == null) return;

              final request = LeaseRequest(
                id: DateTime.now().millisecondsSinceEpoch,
                productId: product.id,
                productName: product.name,
                pricePerDay: product.price,
                totalDays: 1,
                requesterId: user.id,
                requesterFirstName: user.firstName,
                requesterLastName: user.lastName,
                requesterAvatarPath: user.avatarPath,
                ownerId: product.ownerId,
                images: product.images,
              );
              context.read<LeaseRequestProvider>().addRequest(request);

              final leasesProvider = context.read<ActiveLeasesProvider>();
              leasesProvider.addActiveLease(ActiveLease(
                productId: product.id,
                name: product.name,
                pricePerDay: product.price,
                startDate: null,
                totalDays: 1,
                userId: user.id,
                ownerId: product.ownerId,
                userFirstName: user.firstName,
                userLastName: user.lastName,
                userAvatarPath: user.avatarPath,
                status: LeaseStatus.pending,
              ));

              SnackBarCustom.show(context, message: 'Запрос на аренду отправлен');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.copper,
              foregroundColor: AppColors.spaceCream,
              padding: const EdgeInsets.symmetric(vertical: 5),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('Арендовать', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final user = context.read<AuthProvider>().currentUser;
              if (user == null) return;
              final authProvider = context.read<AuthProvider>();
              final owner = await authProvider.getUserById(product.ownerId);
              final productImage = product.images.isNotEmpty ? product.images[0] : null;
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
                MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.whiteAntique,
              foregroundColor: AppColors.oliveGray,
              side: BorderSide(color: AppColors.oliveGray.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.symmetric(vertical: 5),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Написать продавцу',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}