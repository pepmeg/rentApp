import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../provider/favorite_provider.dart';
import '../provider/AuthProvider.dart';
import '../utils/colors.dart';
import '../widgets/product_screen/product_details_section.dart';
import '../widgets/product_screen/product_image_gallery.dart';
import '../widgets/product_screen/product_info_section.dart';
import '../widgets/product_screen/product_owner_info.dart';
import '../widgets/product_screen/product_reviews/product_reviews_section.dart';

class ProductScreen extends StatelessWidget {
  final Product product;

  const ProductScreen({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = context.watch<FavoriteProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final userId = currentUser?.id;

    final isFavorite = userId != null && favoriteProvider.isFavorite(userId, product.id);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24, color: AppColors.oliveGray),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  if (userId != null)
                    GestureDetector(
                      onTap: () => favoriteProvider.toggleFavorite(userId, product.id),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? AppColors.copper : AppColors.oliveGray,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
            ProductImageGallery(images: product.images),
            const SizedBox(height: 20),
            ProductInfoSection(product: product),
            const SizedBox(height: 20),
            ProductDetailsSection(product: product),
            const SizedBox(height: 20),
            ProductOwnerInfo(
              futureOwner: product.ownerId > 0
                  ? authProvider.getUserById(product.ownerId)
                  : Future.value(null),
            ),
            const SizedBox(height: 20),
            ProductReviewsSection(product: product),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}