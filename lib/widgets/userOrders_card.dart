import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // добавьте пакет intl
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/product_image.dart';

class UserOrdersCard extends StatelessWidget {
  final int id;
  final String name;
  final int price;
  final List<String> images;
  final String location;
  final DateTime createdAt;
  final VoidCallback onEdit;

  const UserOrdersCard({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.location,
    required this.createdAt,
    required this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd.MM.yyyy').format(createdAt);
    return Card(
      color: AppColors.whiteAntique,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(
              images: images,
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
                    name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$price ₽ в день',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                  ),
                  const SizedBox(height: 2),
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
                          location,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.oliveGray.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Дата выставления: $dateFormatted',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.oliveGray.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: const Icon(
                Icons.edit,
                color: AppColors.oliveGray,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}