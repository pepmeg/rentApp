import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/product.dart';
import '../../../../models/review.dart';
import '../../../provider/AuthProvider.dart';
import '../../../provider/activeLeasesProvider.dart';
import '../../../utils/colors.dart';
import '../../../utils/snackbar_custom.dart';
import '../../../widgets/product_screen/product_reviews/review_card.dart';
import '../../../pages/product_reviews.dart';
import '../../../provider/ReviewsProvider.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final reviewsProvider = context.watch<ReviewsProvider>();
    final reviews = reviewsProvider.getReviewsForProduct(widget.product.id);
    final leasesProvider = context.read<ActiveLeasesProvider>();
    final canReview = user != null &&
        reviewsProvider.canUserReview(user.id, widget.product.id, leasesProvider);

    if (user != null && canReview && _existingReview == null && !_isEditing) {
      _existingReview = reviewsProvider.getUserReview(user.id, widget.product.id);
    }

    final sortedReviews = List<Review>.from(reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Отзывы',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
              const Spacer(),
              if (reviews.length > 5)
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ProductReviewsPage(productId: widget.product.id))),
                  child: Text('Смотреть все',
                      style: TextStyle(fontSize: 13, color: AppColors.oliveGray.withOpacity(0.5))),
                ),
              if (reviews.length > 5) ...[
                const SizedBox(width: 3),
                const Icon(Icons.arrow_circle_right_sharp, size: 10, color: AppColors.oliveGray),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (sortedReviews.isNotEmpty)
            ...sortedReviews.take(5).map((r) {
              if (r.id == _existingReview?.id && _isEditing) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildReviewForm(),
                );
              }
              final isOwn = r.userId == user?.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReviewCard(
                  review: r,
                  onEdit: isOwn ? () => _editReview(r) : null,
                  onDelete: isOwn
                      ? () {
                    reviewsProvider.deleteReview(r.id);
                    setState(() {
                      if (_existingReview?.id == r.id) {
                        _existingReview = null;
                        _isEditing = false;
                        _reviewController.clear();
                      }
                    });
                  }
                      : null,
                ),
              );
            })
          else if (!canReview)
            Center(
              child: Text('Нет отзывов',
                  style: TextStyle(color: AppColors.oliveGray.withOpacity(0.5))),
            ),
          if (canReview && _existingReview == null && !_isEditing)
            _buildReviewForm(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }
}