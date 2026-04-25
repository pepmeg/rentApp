import 'dart:io';
import 'package:flutter/material.dart';
import 'package:untitled/widgets/plural.dart';
import 'package:untitled/widgets/product_image.dart';
import '../utils/colors.dart';

class BasketCard extends StatelessWidget {
  final int id;
  final String name;
  final int price;
  final List<String> images;
  final int days;
  final Function(int) onDaysChanged;
  final VoidCallback onRemove;

  const BasketCard({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.days,
    required this.onDaysChanged,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.whiteAntique,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: AppColors.whiteAntique,
        ),
        child: Column(
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
                      Row(
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
                          const Spacer(),
                          GestureDetector(
                            onTap: onRemove,
                            child: const Icon(
                              Icons.delete_outline,
                              size: 30,
                              color: AppColors.oliveGray,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$price ₽ за день',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: AppColors.oliveGray.withOpacity(0.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: AppColors.spaceCream,
              ),
              child: Row(
                children: [
                  const Text(
                    'Срок аренды',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (days > 1) {
                        onDaysChanged(days - 1);
                      }
                    },
                    child: Icon(
                      Icons.exposure_minus_1,
                      size: 15,
                      color: days > 1
                          ? AppColors.oliveGray
                          : AppColors.oliveGray.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(width: 15),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '$days ${Plural.days(days)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: AppColors.oliveGray,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () {
                      if (days < 99) {
                        onDaysChanged(days + 1);
                      }
                    },
                    child: Icon(
                      Icons.plus_one,
                      size: 15,
                      color: days < 99
                          ? AppColors.oliveGray
                          : AppColors.oliveGray.withOpacity(0.3),
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