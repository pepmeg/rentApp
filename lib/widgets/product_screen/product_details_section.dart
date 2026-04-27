import 'package:flutter/material.dart';
import 'package:untitled/models/product.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/plural.dart';

class ProductDetailsSection extends StatelessWidget {
  final Product product;

  const ProductDetailsSection({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: AppColors.spaceCream,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Подробности', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
            const SizedBox(height: 2),
            _buildRow('Категория:', product.category.isNotEmpty ? product.category : 'Не указана'),
            const SizedBox(height: 5),
            _buildRow('Подкатегория:', product.subcategory.isNotEmpty ? product.subcategory : 'Не указана'),
            const SizedBox(height: 5),
            _buildRow('Бренд:', product.brand.isNotEmpty ? product.brand : 'Не указан'),
            const SizedBox(height: 5),
            _buildRow('Мин. срок аренды:', '${product.minRentDays} ${Plural.days(product.minRentDays)}'),
            const SizedBox(height: 5),
            const Text('Описание', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
            const SizedBox(height: 10),
            Text(
              product.description.isNotEmpty ? product.description : 'Нет описания',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
            ),
            const SizedBox(height: 5),
            const Text('Местоположение', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
            const SizedBox(height: 5),
            Text(
              product.location.isNotEmpty ? product.location : 'Не указано',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray.withOpacity(0.5))),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}