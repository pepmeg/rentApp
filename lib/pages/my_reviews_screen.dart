import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../models/user.dart';
import '../pages/productScreen.dart';
import '../provider/AuthProvider.dart';
import '../provider/ReviewsProvider.dart';
import '../services/product_service.dart';
import '../theme/theme_data.dart';
import '../utils/avatar.dart';
import '../utils/form_fields.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<Product> _userProducts = [];
  List<Review> _allReviews = [];
  List<Review> _filteredReviews = [];
  bool _isLoading = true;
  String? _selectedProductId;
  bool _sortNewestFirst = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    try {
      _userProducts = await ProductService.getAllProducts(ownerId: user.uid);
      _userProducts.removeWhere((p) => p.moderationStatus == 'blocked');

      final reviewsProvider = context.read<ReviewsProvider>();
      await reviewsProvider.loadFromFirestore();
      _allReviews = reviewsProvider.reviews;

      final userProductIds = _userProducts.map((p) => p.id).toSet();
      _allReviews = _allReviews.where((r) => userProductIds.contains(r.productId)).toList();

      _applyFilters();
    } catch (e) {
      debugPrint('Ошибка загрузки: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Review> filtered = List.from(_allReviews);
    if (_selectedProductId != null) {
      filtered = filtered.where((r) => r.productId == _selectedProductId).toList();
    }
    if (_sortNewestFirst) {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    setState(() {
      _filteredReviews = filtered;
    });
  }

  String _getProductName(String productId) {
    return _userProducts.firstWhere((p) => p.id == productId, orElse: () => Product(
      id: '',
      ownerId: '',
      name: 'Товар удалён',
      nameLowercase: 'товар удалён'.toLowerCase(),
      price: 0,
      location: '',
      images: [],
      categoryPath: [],
    )).name;
  }

  Future<void> _onReviewTap(String productId) async {
    final product = await ProductService.getProductById(productId);
    if (product != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  'Отзывы',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppDropdownMenu(
                    value: _selectedProductId == null
                        ? null
                        : _userProducts.firstWhere((p) => p.id == _selectedProductId).name,
                    hint: 'Все товары',
                    options: [
                      'Все товары',
                      ..._userProducts.map((p) => p.name),
                    ],
                    onChanged: (selectedName) {
                      if (selectedName == null || selectedName == 'Все товары') {
                        setState(() => _selectedProductId = null);
                      } else {
                        final product = _userProducts.firstWhere((p) => p.name == selectedName);
                        setState(() => _selectedProductId = product.id);
                      }
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() => _sortNewestFirst = !_sortNewestFirst);
                    _applyFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 18,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _sortNewestFirst ? 'Сначала новые' : 'Сначала старые',
                          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                  : _filteredReviews.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.comment_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'Нет отзывов на ваши товары',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ],
                ),
              )
                  : ListView.separated(
                itemCount: _filteredReviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final review = _filteredReviews[index];
                  final productName = _getProductName(review.productId);
                  final dateFormatted = DateFormat('dd MMM yyyy', 'ru').format(review.createdAt);
                  final rating = review.rating;

                  return GestureDetector(
                    onTap: () => _onReviewTap(review.productId),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ?? theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.onSurface.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              FutureBuilder<UserModel?>(
                                future: context.read<AuthProvider>().getUserById(review.userId),
                                builder: (context, snapshot) {
                                  final author = snapshot.data;
                                  return buildUserAvatar(author, radius: 20);
                                },
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review.userName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateFormatted,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  productName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(5, (i) => Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              size: 18,
                              color: AppTheme.starColor,
                            )),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review.text,
                            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}