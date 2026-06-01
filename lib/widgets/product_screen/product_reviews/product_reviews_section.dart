import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/product.dart';
import '../../../../models/review.dart';
import '../../../provider/AuthProvider.dart';
import '../../../provider/activeLeasesProvider.dart';
import '../../../provider/ReviewsProvider.dart';
import '../../../theme/theme_data.dart';
import '../../../utils/snackbar_custom.dart';
import '../../../widgets/product_screen/product_reviews/review_card.dart';
import '../../../pages/product_reviews.dart';

class ProductReviewsSection extends StatefulWidget {
  final Product product;
  const ProductReviewsSection({required this.product, super.key});

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 5;
  String? _editingReviewId;
  bool get _isEditing => _editingReviewId != null;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submitReview() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final reviewsProvider = context.read<ReviewsProvider>();
    final text = _reviewController.text.trim();
    if (text.isEmpty) {
      SnackBarCustom.show(context, message: 'Введите текст отзыва');
      return;
    }

    if (_isEditing) {
      await reviewsProvider.updateReview(_editingReviewId!, _rating, text);
      SnackBarCustom.show(context, message: 'Отзыв обновлён');
      _cancelEditing();
    } else {
      final review = Review(
        id: '',
        productId: widget.product.id,
        userId: user.uid,
        userName: '${user.firstName} ${user.lastName}',
        userAvatarPath: user.avatarUrl ?? '',
        createdAt: DateTime.now(),
        rating: _rating,
        text: text,
      );
      await reviewsProvider.addReview(review);
      SnackBarCustom.show(context, message: 'Отзыв добавлен');
      _clearForm();
    }
  }

  void _editReview(Review review) {
    setState(() {
      _editingReviewId = review.id;
      _reviewController.text = review.text;
      _rating = review.rating;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingReviewId = null;
      _reviewController.clear();
      _rating = 5;
    });
  }

  void _clearForm() {
    setState(() {
      _editingReviewId = null;
      _reviewController.clear();
      _rating = 5;
    });
  }

  void _confirmDelete(Review review) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        title: Text('Удалить отзыв?', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text('Отзыв будет удалён безвозвратно.', style: TextStyle(color: theme.colorScheme.onSurface)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Отмена', style: TextStyle(color: theme.colorScheme.onSurface))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ReviewsProvider>().deleteReview(review.id);
              if (_editingReviewId == review.id) _cancelEditing();
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final reviewsProvider = context.watch<ReviewsProvider>();
    final allReviews = reviewsProvider.getReviewsForProduct(widget.product.id);
    final leasesProvider = context.read<ActiveLeasesProvider>();
    final canReview = user != null && reviewsProvider.canUserReview(user.uid, widget.product.id, leasesProvider);

    final sortedReviews = List<Review>.from(allReviews)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final userReview = (canReview && user != null) ? reviewsProvider.getUserReview(user.uid, widget.product.id) : null;
    final bool hasUserReview = userReview != null && !_isEditing;
    final isBlocked = user?.blocked == true;
    final theme = Theme.of(context);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Отзывы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const Spacer(),
            if (allReviews.length > 5)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductReviewsPage(productId: widget.product.id))),
                child: Text('Смотреть все', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ),
            if (allReviews.length > 5) ...[
              const SizedBox(width: 3),
              Icon(Icons.arrow_circle_right_sharp, size: 10, color: theme.colorScheme.onSurface),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (sortedReviews.isNotEmpty)
          ...sortedReviews.take(5).map((r) {
            final isOwn = r.userId == user?.uid;
            if (_isEditing && _editingReviewId == r.id) {
              return Padding(padding: const EdgeInsets.only(bottom: 10), child: _buildReviewForm());
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReviewCard(review: r, onEdit: isOwn ? () => _editReview(r) : null, onDelete: isOwn ? () => _confirmDelete(r) : null),
            );
          }),
        if (sortedReviews.isEmpty && !canReview)
          Center(child: Text('Нет отзывов', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)))),
        if (canReview && !hasUserReview && !_isEditing && !isBlocked) _buildReviewForm(),
        const SizedBox(height: 20),
      ],
    );
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: content);
  }

  Widget _buildReviewForm() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) => IconButton(
            icon: Icon(i < _rating ? Icons.star : Icons.star_border, color: AppTheme.starColor, size: 28),
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
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            filled: true,
            fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_isEditing ? 'Сохранить изменения' : 'Оставить отзыв'),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(width: 10),
              TextButton(onPressed: _cancelEditing, child: Text('Отмена', style: TextStyle(color: theme.colorScheme.onSurface))),
            ],
          ],
        ),
      ],
    );
  }
}