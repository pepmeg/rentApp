import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/AuthProvider.dart';
import '../provider/ReviewsProvider.dart';
import '../provider/favorite_provider.dart';
import '../utils/colors.dart';

class ProductCard extends StatefulWidget {
  final int id;
  final String name;
  final int price;
  final String location;
  final List<String> images;
  final bool isPricePerHour;
  final VoidCallback? onTap;

  const ProductCard({
    required this.id,
    required this.name,
    required this.price,
    required this.location,
    required this.images,
    this.isPricePerHour = false,
    this.onTap,
    super.key,
  });

  @override
  State<ProductCard> createState() => ProductCardState();
}

class ProductCardState extends State<ProductCard> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    final isFavorite = userId != null ? favoriteProvider.isFavorite(userId, widget.id) : false;
    final isUser = context.read<AuthProvider>().isUser;

    final reviews = context.watch<ReviewsProvider>()
        .getReviewsForProduct(widget.id);
    final double avgRating = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    final String ratingText = reviews.isEmpty
        ? '—'
        : avgRating.toStringAsFixed(1);

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        color: AppColors.whiteAntique,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: widget.images.isNotEmpty
                      ? (widget.images[0].startsWith('assets/')
                      ? Image.asset(
                    widget.images[0],
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                      : Image.file(
                    File(widget.images[0]),
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 110,
                      color: AppColors.oliveGray,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ))
                      : Container(
                    height: 110,
                    width: double.infinity,
                    color: AppColors.oliveGray,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      if (userId != null && isUser) {
                        favoriteProvider.toggleFavorite(userId, widget.id);
                      }
                    },
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppColors.copper : AppColors.oliveGray,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.oliveGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        color: AppColors.yellowSchoolBus,
                        size: 18,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        ratingText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: AppColors.oliveGray.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.isPricePerHour
                        ? '${widget.price} ₽/час'
                        : '${widget.price} ₽/день',
                    style: TextStyle(fontSize: 15, color: AppColors.oliveGray),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.oliveGray,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.oliveGray.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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