import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/provider/favorite_provider.dart';
import 'package:untitled/utils/colors.dart';

class ProductCard extends StatefulWidget {
  final int id;
  final String name;
  final int price;
  final String location;
  final String image;
  final VoidCallback? onTap;

  const ProductCard({
    required this.id,
    required this.name,
    required this.price,
    required this.location,
    required this.image,
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
  final isFavorite = favoriteProvider.isFavorite(widget.id);
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
                  child: Image.asset(
                    widget.image,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
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
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.oliveGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacer(),
                      Icon(
                        Icons.star,
                        color: AppColors.yellowSchoolBus,
                        size: 20,
                      ),
                      Text(
                        '4.8',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: AppColors.oliveGray,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${widget.price} ₽/день',
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
                            color: AppColors.oliveGray,
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
