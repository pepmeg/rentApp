import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../services/category_service.dart';
import '../../widgets/plural.dart';

class ProductDetailsSection extends StatelessWidget {
  final Product product;

  const ProductDetailsSection({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    final categoryService = context.watch<CategoryService>();
    final theme = Theme.of(context);

    String categoryName = 'Не указана';
    String subcategoryName = '';
    if (product.categoryPath.isNotEmpty) {
      final rootId = product.categoryPath.first;
      final rootNode = categoryService.getCategoryById(rootId);
      categoryName = rootNode?.name ?? 'Не указана';
      if (product.categoryPath.length > 1) {
        final subId = product.categoryPath[1];
        final subNode = categoryService.getCategoryById(subId);
        subcategoryName = subNode?.name ?? '';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Подробности',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            _buildRow(context, 'Категория:', categoryName),
            if (subcategoryName.isNotEmpty) ...[
              const SizedBox(height: 5),
              _buildRow(context, 'Подкатегория:', subcategoryName),
            ],
            const SizedBox(height: 5),
            _buildRow(context, 'Бренд:', product.brand.isNotEmpty ? product.brand : 'Не указан'),
            const SizedBox(height: 5),
            _buildRow(
              context,
              'Мин. срок аренды:',
              product.isPricePerHour
                  ? '${product.minRentHours} ${Plural.hours(product.minRentHours)}'
                  : '${product.minRentDays} ${Plural.days(product.minRentDays)}',
            ),
            const SizedBox(height: 5),
            Text(
              'Описание',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.description.isNotEmpty ? product.description : 'Нет описания',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Местоположение',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              product.location.isNotEmpty ? product.location : 'Не указано',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}