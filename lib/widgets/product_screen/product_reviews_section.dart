import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/models/product.dart';
import 'package:untitled/models/review.dart';
import 'package:untitled/provider/AuthProvider.dart';
import 'package:untitled/provider/activeLeasesProvider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/utils/snackbar_custom.dart';
import 'package:untitled/widgets/review_card.dart';
import '../../pages/product_reviews.dart';
import '../../provider/ReviewsProvider.dart';

class ProductReviewsSection extends StatefulWidget {
  final Product product;
  const ProductReviewsSection({required this.product, super.key});

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 5;
  bool _isEditing = false;
  Review? _existingReview;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submitReview() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final reviewsProvider = context.read<ReviewsProvider>();
    final text = _reviewController.text.trim();
    if (text.isEmpty) {
      SnackBarCustom.show(context, message: 'Введите текст отзыва');
      return;
    }

    if (_isEditing && _existingReview != null) {
      reviewsProvider.updateReview(_existingReview!.id, _rating, text);
      SnackBarCustom.show(context, message: 'Отзыв обновлён');
    } else {
      final review = Review(
        id: DateTime.now().millisecondsSinceEpoch,
        productId: widget.product.id,
        userId: user.id,
        userName: '${user.firstName} ${user.lastName}',
        userAvatarPath: user.avatarPath ?? '',
        createdAt: DateTime.now(),
        rating: _rating,
        text: text,
      );
      reviewsProvider.addReview(review);
      SnackBarCustom.show(context, message: 'Отзыв добавлен');
    }

    _reviewController.clear();
    setState(() {
      _rating = 5;
      _isEditing = false;
      _existingReview = null;
    });
  }

  void _editReview(Review review) {
    setState(() {
      _isEditing = true;
      _existingReview = review;
      _reviewController.text = review.text;
      _rating = review.rating;
    });
  }

  void _deleteReview() {
    if (_existingReview == null) return;
    context.read<ReviewsProvider>().deleteReview(_existingReview!.id);
    setState(() {
      _isEditing = false;
      _existingReview = null;
      _reviewController.clear();
      _rating = 5;
    });
    SnackBarCustom.show(context, message: 'Отзыв удалён');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final reviews = context.watch<ReviewsProvider>()
        .getReviewsForProduct(widget.product.id);
    final leasesProvider = context.read<ActiveLeasesProvider>();
    final canReview = user != null &&
        context.read<ReviewsProvider>().canUserReview(user.id, widget.product.id, leasesProvider);

    if (user != null && canReview && _existingReview == null && !_isEditing) {
      _existingReview = context.read<ReviewsProvider>().getUserReview(user.id, widget.product.id);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Отзывы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
              const Spacer(),
              if (reviews.length > 5)
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ProductReviewsPage(productId: widget.product.id))),
                  child: Text('Смотреть все', style: TextStyle(fontSize: 13, color: AppColors.oliveGray.withOpacity(0.5))),
                ),
              if (reviews.length > 5) ...[
                const SizedBox(width: 3),
                const Icon(Icons.arrow_circle_right_sharp, size: 10, color: AppColors.oliveGray),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (reviews.isEmpty)
            const Center(child: Text('Пока нет отзывов', style: TextStyle(color: AppColors.oliveGray)))
          else
            ...reviews
                .where((r) => r.id != _existingReview?.id)
                .take(5)
                .map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReviewCard(review: r),
            )),
          if (canReview && _existingReview != null && !_isEditing) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReviewCard(
                review: _existingReview!,
                onEdit: () => _editReview(_existingReview!),
                onDelete: () => _deleteReview(),
              ),
            ),
          ],
          if (canReview && (_existingReview == null || _isEditing)) ...[
            const SizedBox(height: 20),
            Row(
              children: List.generate(5, (i) => IconButton(
                icon: Icon(i < _rating ? Icons.star : Icons.star_border,
                    color: AppColors.yellowSchoolBus, size: 28),
                onPressed: () => setState(() => _rating = i + 1),
              )),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ваш отзыв...',
                hintStyle: TextStyle(color: AppColors.oliveGray.withOpacity(0.5)),
                filled: true,
                fillColor: AppColors.whiteAntique,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.copper,
                      foregroundColor: AppColors.whiteAntique,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_isEditing ? 'Сохранить изменения' : 'Оставить отзыв'),
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _existingReview = null;
                        _reviewController.clear();
                        _rating = 5;
                      });
                    },
                    child: const Text('Отмена'),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}