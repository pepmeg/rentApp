import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/product_screen/product_reviews/review_card.dart';
import '../provider/ReviewsProvider.dart';

class ProductReviewsPage extends StatelessWidget {
  final String productId;
  const ProductReviewsPage({required this.productId, super.key});

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewsProvider>()
        .getReviewsForProduct(productId);
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 24, color: theme.colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 5),
                Text(
                  'Все отзывы',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: reviews.isEmpty
                  ? Center(
                child: Text(
                  'Нет отзывов',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              )
                  : ListView.builder(
                itemCount: reviews.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ReviewCard(review: reviews[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}