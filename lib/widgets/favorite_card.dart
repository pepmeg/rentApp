import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../pages/productScreen.dart';
import '../provider/AuthProvider.dart';
import '../provider/favorite_provider.dart';
import 'product_image.dart';

class FavoriteCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onRemove;
  final bool cacheUrls;

  const FavoriteCard({
    required this.product,
    this.onRemove,
    this.cacheUrls = false,
    super.key,
  });

  @override
  State<FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends State<FavoriteCard> {
  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.uid;
    final isFavorite = userId != null ? favoriteProvider.isFavorite(userId, widget.product.id) : false;
    final product = widget.product;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
        );
      },
      child: Card(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImage(
                images: product.images,
                width: 100,
                height: 100,
                backgroundColor: theme.colorScheme.surface,
                cacheUrls: widget.cacheUrls,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.isPricePerHour
                          ? '${product.price} ₽ в час'
                          : '${product.price} ₽ в день',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (userId != null) {
                    final wasFavorite = isFavorite;
                    favoriteProvider.toggleFavorite(userId, product.id);
                    if (wasFavorite && widget.onRemove != null) {
                      widget.onRemove!();
                    }
                    setState(() {});
                  }
                },
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
            ],
          ),
        ),
      ),
    );
  }
}