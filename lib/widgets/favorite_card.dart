import 'package:AppRent/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/product_data.dart';
import '../pages/productScreen.dart';
import '../provider/favorite_provider.dart';
import '../utils/colors.dart';
import '../utils/snackbar_custom.dart';

class FavoriteCard extends StatefulWidget {
  final int id;
  final String name;
  final int price;
  final List<String> images;
  final String location;
  final bool isPricePerHour;

  const FavoriteCard({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.location,
    this.isPricePerHour = false,
    super.key,
  });

  @override
  State<FavoriteCard> createState() => FavoriteCardState();
}

class FavoriteCardState extends State<FavoriteCard> {
  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final isFavorite = favoriteProvider.isFavorite(widget.id);

    return GestureDetector(
      onTap: () {
        final product = ProductData.getProductById(widget.id);
        if (product != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductScreen(product: product)),
          );
        } else {
          SnackBarCustom.show(context, message: 'Товар не найден');
        }
      },
      child: Card(
        color: AppColors.whiteAntique,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImage(
                images: widget.images,
                width: 100,
                height: 100,
                backgroundColor: AppColors.whiteAntique,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: AppColors.oliveGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.isPricePerHour
                          ? '${widget.price} ₽ в час'
                          : '${widget.price} ₽ в день',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: AppColors.oliveGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: AppColors.oliveGray.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    favoriteProvider.toggleFavorite(widget.id);
                  });
                },
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppColors.copper : AppColors.oliveGray,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}