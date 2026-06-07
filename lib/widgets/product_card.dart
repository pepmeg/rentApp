import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../provider/AuthProvider.dart';
import '../provider/ReviewsProvider.dart';
import '../provider/favorite_provider.dart';
import '../services/storage_service.dart';
import '../theme/theme_data.dart';

class ProductCard extends StatefulWidget {
  final String id;
  final String name;
  final int price;
  final String location;
  final List<String> images;
  final bool isPricePerHour;
  final String ownerId;
  final VoidCallback? onTap;
  final bool cacheUrls;

  const ProductCard({
    required this.id,
    required this.name,
    required this.price,
    required this.location,
    required this.images,
    required this.ownerId,
    this.isPricePerHour = false,
    this.onTap,
    this.cacheUrls = false,
    super.key,
  });

  @override
  State<ProductCard> createState() => ProductCardState();
}

class ProductCardState extends State<ProductCard> {
  Future<String?>? _imageFuture;

  @override
  void initState() {
    super.initState();
    _initImageFuture();
  }

  @override
  void didUpdateWidget(ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images.isNotEmpty && oldWidget.images.isNotEmpty &&
        widget.images[0] != oldWidget.images[0]) {
      _initImageFuture();
    }
  }

  void _initImageFuture() {
    if (widget.images.isNotEmpty) {
      _imageFuture = _resolveUrl(widget.images[0]);
    } else {
      _imageFuture = null;
    }
  }

  Future<String?> _resolveUrl(String objectKey) async {
    final cached = await StorageService.getCachedUrl(objectKey);
    if (cached != null) return cached;
    try {
      return await StorageService.getDownloadUrl(objectKey, cache: widget.cacheUrls)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Ошибка загрузки изображения $objectKey: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = context.watch<FavoriteProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    final userId = user?.uid;
    final isBlocked = user?.blocked ?? false;
    final isOwner = userId == widget.ownerId;
    final isUser = authProvider.isUser;
    final isFavorite = userId != null && favoriteProvider.isFavorite(userId, widget.id);
    final theme = Theme.of(context);

    final reviews = context.watch<ReviewsProvider>().getReviewsForProduct(widget.id);
    final double avgRating = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    final String ratingText = reviews.isEmpty ? '—' : avgRating.toStringAsFixed(1);

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: _buildImage(theme),
                ),
                if (!isOwner && userId != null && isUser && !isBlocked)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        favoriteProvider.toggleFavorite(userId, widget.id);
                        setState(() {});
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/heart.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              isFavorite ? theme.primaryColor : theme.colorScheme.onSurface,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
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
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.star, color: AppTheme.starColor, size: 18),
                      const SizedBox(width: 2),
                      Text(
                        ratingText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isPricePerHour ? '${widget.price} ₽/час' : '${widget.price} ₽/день',
                    style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: theme.colorScheme.onSurface),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
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

  Widget _buildImage(ThemeData theme) {
    if (widget.images.isEmpty) {
      return Container(
        height: 110,
        width: double.infinity,
        color: theme.colorScheme.onSurface.withOpacity(0.3),
        child: const Icon(Icons.image_not_supported),
      );
    }
    final path = widget.images[0];
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: path,
        height: 110,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 110,
          width: double.infinity,
          color: theme.colorScheme.onSurface.withOpacity(0.1),
          child: Center(child: CircularProgressIndicator(strokeWidth: 5, color: theme.primaryColor)),
        ),
        errorWidget: (context, url, error) => Container(
          height: 110,
          width: double.infinity,
          color: theme.colorScheme.onSurface.withOpacity(0.3),
          child: const Icon(Icons.broken_image),
        ),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        height: 110,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 110,
          width: double.infinity,
          color: theme.colorScheme.onSurface.withOpacity(0.3),
          child: const Icon(Icons.broken_image),
        ),
      );
    }

    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        height: 110,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 110,
          width: double.infinity,
          color: theme.colorScheme.onSurface.withOpacity(0.3),
          child: const Icon(Icons.broken_image),
        ),
      );
    }

    return FutureBuilder<String?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 110,
            width: double.infinity,
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            child: Center(child: CircularProgressIndicator(strokeWidth: 5, color: theme.primaryColor)),
          );
        }
        final url = snapshot.data;
        if (url == null || url.isEmpty) {
          return Container(
            height: 110,
            width: double.infinity,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
            child: const Icon(Icons.broken_image),
          );
        }
        return CachedNetworkImage(
          imageUrl: url,
          height: 110,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 110,
            width: double.infinity,
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            child: Center(child: CircularProgressIndicator(strokeWidth: 5, color: theme.primaryColor)),
          ),
          errorWidget: (context, url, error) => Container(
            height: 110,
            width: double.infinity,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
            child: const Icon(Icons.broken_image),
          ),
        );
      },
    );
  }
}