import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../provider/AuthProvider.dart';
import '../provider/favorite_provider.dart';
import '../services/category_service.dart';
import '../utils/pagination.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/favorite_card.dart';
import '../widgets/search_field.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => FavoriteState();
}

class FavoriteState extends State<Favorite> with PaginationMixin {
  String searchQuery = '';
  List<String>? _selectedCategoryPath;
  late FavoriteProvider _favProvider;

  List<Product> _allFavorites = [];
  bool _isLoading = false;

  @override
  int get paginationBatchSize => 8;

  @override
  List<dynamic> get paginationItems => _filteredProducts;

  List<Product> get _filteredProducts {
    var list = _allFavorites;
    if (_selectedCategoryPath != null && _selectedCategoryPath!.isNotEmpty) {
      final prefix = _selectedCategoryPath!;
      list = list.where((p) {
        if (p.categoryPath.length < prefix.length) return false;
        for (int i = 0; i < prefix.length; i++) {
          if (p.categoryPath[i] != prefix[i]) return false;
        }
        return true;
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      list = list
          .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return list;
  }

  @override
  void initState() {
    super.initState();
    _favProvider = context.read<FavoriteProvider>();
    _favProvider.addListener(_onFavoritesChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!context.read<AuthProvider>().isUser) {
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }
      await _loadFavorites();
    });
  }

  @override
  void dispose() {
    _favProvider.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (!mounted) return;
    if (_favProvider.andClearFavoritesChanged) {
      _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;
      await _favProvider.loadFavoritesForUser(user.uid);
      final favoriteIds = _favProvider.getFavoritesForUser(user.uid).toList();
      final products = await ProductService.getProductsByIds(favoriteIds);
      _allFavorites = products.where((p) => p.moderationStatus == 'active').toList();
    } catch (e) {
      debugPrint('Ошибка загрузки избранного: $e');
    }
    setState(() => _isLoading = false);
  }

  void _handleRemoveFavorite(String productId) {
    setState(() {
      _allFavorites.removeWhere((p) => p.id == productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<CategoryService>();
    final items = _filteredProducts;
    final visibleItems = items.take(visibleCount).toList();
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          children: [
            SearchField(
              hintText: 'Поиск',
              padding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() => searchQuery = value);
                resetPagination();
              },
            ),
            const SizedBox(height: 15),
            CategoryFilterBar(
              onFilterChanged: (path) {
                setState(() {
                  _selectedCategoryPath = path;
                  resetPagination();
                });
              },
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                  : items.isEmpty
                  ? const EmptyState(
                svgAsset: 'assets/icons/heart.svg',
                title: 'Нет избранных товаров',
              )
                  : ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: visibleItems.length,
                itemBuilder: (context, index) {
                  final product = visibleItems[index];
                  final user = context.read<AuthProvider>().currentUser;
                  return FavoriteCard(
                    product: product,
                    onRemove: () => _handleRemoveFavorite(product.id),
                    cacheUrls: user?.uid == product.ownerId,
                  );
                },
              ),
            ),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(color: theme.primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}