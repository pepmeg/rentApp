import 'package:flutter/material.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/product_image.dart';
import 'package:untitled/widgets/plural.dart';

class BasketCard extends StatelessWidget {
  final int id;
  final String name;
  final int price;
  final List<String> images;
  final int days;

  const BasketCard({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.days,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final int totalPrice = price * days;

    return Card(
      color: AppColors.whiteAntique,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: AppColors.whiteAntique,
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
                    images: images,
                    width: 80,
                    height: 80,
                    backgroundColor: AppColors.whiteAntique,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: AppColors.oliveGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$price ₽ × $days ${Plural.days(days)} = $totalPrice ₽',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: AppColors.oliveGray.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: AppColors.oliveGray.withOpacity(0.1),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.copper.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: AppColors.copper),
                  const SizedBox(width: 8),
                  Text(
                    'Оплатите в течение 24 часов',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.copper,
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