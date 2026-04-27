import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/product_screen/product_reviews/review_card.dart';
import '../provider/ReviewsProvider.dart';

class ProductReviewsPage extends StatelessWidget {
  final int productId;
  const ProductReviewsPage({required this.productId, super.key});

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewsProvider>()
        .getReviewsForProduct(productId);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 24, color: AppColors.oliveGray),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 5),
                const Text('Все отзывы', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: reviews.isEmpty
                  ? const Center(child: Text('Нет отзывов', style: TextStyle(color: AppColors.oliveGray)))
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