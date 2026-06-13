import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activeLease.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../provider/AuthProvider.dart';
import '../provider/activeLeasesProvider.dart';
import '../provider/bottom_nav_provider.dart';
import '../provider/ReviewsProvider.dart';
import '../services/category_service.dart';
import '../services/connectivityService.dart';
import '../utils/pagination.dart';
import '../widgets/category_filter.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_card.dart';
import '../widgets/search_field.dart';
import 'productScreen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> with PaginationMixin, WidgetsBindingObserver {
  String searchQuery = '';
  List<String>? _selectedCategoryPath;
  int? minPrice;
  int? maxPrice;
  String? brandFilter;
  String? regionFilter;
  String? cityFilter;
  String? sortMode;

  List<Product> _allProducts = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _needsRefresh = true;
  DateTime? _lastLoadTime;

  static const String _cachedProductsKey = 'cached_active_products';

  @override
  int get paginationBatchSize => 8;

  @override
  List<dynamic> get paginationItems => filteredProducts;

  List<Product> get filteredProducts {
    var list = _allProducts;

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((p) => p.nameLowercase.contains(q)).toList();
    }

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

    if (minPrice != null) {
      list = list.where((p) => p.price >= minPrice!).toList();
    }
    if (maxPrice != null) {
      list = list.where((p) => p.price <= maxPrice!).toList();
    }
    if (brandFilter != null && brandFilter!.isNotEmpty) {
      list = list.where((p) => p.brand == brandFilter).toList();
    }
    if (regionFilter != null && regionFilter!.isNotEmpty) {
      list = list.where((p) => p.region == regionFilter).toList();
    }
    if (cityFilter != null && cityFilter!.isNotEmpty) {
      list = list.where((p) => p.city == cityFilter).toList();
    }

    final activeLeaseProductIds = context.read<ActiveLeasesProvider>()
        .leases
        .where((l) => l.status == LeaseStatus.active || l.status == LeaseStatus.pendingCompletion)
        .map((l) => l.productId)
        .toSet();
    list = list.where((p) => !activeLeaseProductIds.contains(p.id)).toList();
    list = list.where((p) => p.moderationStatus == 'active').toList();

    final reviewsProvider = context.read<ReviewsProvider>();
    double getRating(Product p) {
      final reviews = reviewsProvider.getReviewsForProduct(p.id);
      if (reviews.isEmpty) return 0.0;
      return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    }

    switch (sortMode) {
      case 'price_asc':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        list.sort((a, b) => getRating(b).compareTo(getRating(a)));
        break;
      case 'date_desc':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return list;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCachedProducts();
    _loadProducts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _needsRefresh = true;
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cachedProductsKey);
      if (jsonString != null) {
        final List<dynamic> list = jsonDecode(jsonString);
        final cached = list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        if (mounted && cached.isNotEmpty) {
          setState(() {
            _allProducts = cached;
            _isLoading = false;
            _hasError = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Ошибка загрузки кеша товаров: $e');
    }
  }

  Future<void> _saveProductsToCache(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = products.map((p) => p.toJson()).toList();
      await prefs.setString(_cachedProductsKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Ошибка сохранения кеша товаров: $e');
    }
  }

  Future<void> _loadProducts() async {
    if (!_needsRefresh && _allProducts.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final connectivity = context.read<ConnectivityService>();

      if (!connectivity.hasInternet) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('moderationStatus', isEqualTo: 'active')
          .get()
          .timeout(const Duration(seconds: 10));

      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();

      if (mounted) {
        setState(() {
          _allProducts = products;
          _isLoading = false;
          _hasError = false;
          _needsRefresh = false;
          _lastLoadTime = DateTime.now();
        });
        _saveProductsToCache(products);
      }
    } catch (e) {
      debugPrint('Ошибка загрузки товаров: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _refreshProducts() async {
    _needsRefresh = true;
    await _loadProducts();
  }

  void _retryLoading() {
    _needsRefresh = true;
    _loadProducts();
  }

  void _openFilterSheet() {
    final Set<String> regionsSet = {};
    final Map<String, Set<String>> regionToCitiesMap = {};

    for (final product in _allProducts) {
      if (product.region.isNotEmpty) {
        regionsSet.add(product.region);

        if (product.city.isNotEmpty) {
          regionToCitiesMap.putIfAbsent(product.region, () => {});
          regionToCitiesMap[product.region]!.add(product.city);
        }
      }
    }

    final availableRegions = regionsSet.toList()..sort();
    final regionToCities = regionToCitiesMap.map(
          (region, cities) => MapEntry(region, cities.toList()..sort()),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CategoryFilterSheet(
        initialCategoryPath: _selectedCategoryPath,
        initialMinPrice: minPrice,
        initialMaxPrice: maxPrice,
        initialBrand: brandFilter,
        initialRegion: regionFilter,
        initialCity: cityFilter,
        initialSort: sortMode,
        availableRegions: availableRegions,
        regionToCities: regionToCities,
        onApply: (categoryPath, minP, maxP, brand, region, city, sort) {
          setState(() {
            _selectedCategoryPath = categoryPath;
            minPrice = minP;
            maxPrice = maxP;
            brandFilter = brand;
            regionFilter = region;
            cityFilter = city;
            sortMode = sort;
            resetPagination();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavProvider = context.watch<BottomNavProvider>();
    context.watch<AuthProvider>();
    context.watch<ActiveLeasesProvider>();
    context.watch<ReviewsProvider>();
    context.watch<CategoryService>();
    final connectivity = context.watch<ConnectivityService>();
    final currentUser = context.watch<AuthProvider>().currentUser;
    if (bottomNavProvider.currentIndex == 0 && _needsRefresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProducts();
      });
    }
    final allProducts = filteredProducts;
    final visibleProducts = allProducts.take(visibleCount).toList();
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          children: [
            SearchField(
              hintText: 'Поиск',
              padding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  resetPagination();
                });
              },
              suffixIcon: IconButton(
                icon: Icon(Icons.filter_list, color: theme.primaryColor),
                onPressed: _openFilterSheet,
              ),
            ),
            Expanded(
              child: _buildBody(allProducts, visibleProducts, currentUser, connectivity),
            ),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator(color: theme.primaryColor)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Product> allProducts, List<Product> visibleProducts,
      UserModel? currentUser, ConnectivityService connectivity) {
    final theme = Theme.of(context);

    if (_isLoading && !_hasError && allProducts.isEmpty) {
      return Center(child: CircularProgressIndicator(color: theme.primaryColor));
    }

    if (_hasError) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: 'Нет соединения с интернетом',
        subtitle: 'Проверьте подключение и попробуйте снова',
        buttonText: 'Повторить',
        onButtonPressed: _retryLoading,
      );
    }

    if (allProducts.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Ничего не найдено',
        subtitle: 'Попробуйте изменить параметры поиска',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshProducts,
      color: theme.primaryColor,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.84,
        ),
        itemCount: visibleProducts.length,
        itemBuilder: (context, index) {
          final product = visibleProducts[index];
          return ProductCard(
            key: ValueKey(product.id),
            id: product.id,
            name: product.name,
            price: product.price,
            location: product.location,
            images: product.images,
            isPricePerHour: product.isPricePerHour,
            ownerId: product.ownerId,
            cacheUrls: currentUser?.uid == product.ownerId,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductScreen(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}