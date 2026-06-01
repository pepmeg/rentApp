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
import '../widgets/product_card.dart';
import 'productScreen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> with PaginationMixin {
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
  late StreamSubscription<QuerySnapshot> _productsSubscription;

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
    _loadCachedProducts();
    _listenToProductsWithFallback();
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

  void _listenToProductsWithFallback() {
    final connectivity = context.read<ConnectivityService>();
    Timer? timeoutTimer;
    bool dataReceived = false;

    timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!dataReceived && mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        _productsSubscription.cancel();
      }
    });

    _productsSubscription = FirebaseFirestore.instance
        .collection('products')
        .where('moderationStatus', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      dataReceived = true;
      timeoutTimer?.cancel();

      final products = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();

      setState(() {
        _allProducts = products;
        _isLoading = false;
        _hasError = false;
      });
      if (connectivity.hasInternet) {
        _saveProductsToCache(products);
      }
    }, onError: (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    });
  }

  @override
  void dispose() {
    _productsSubscription.cancel();
    super.dispose();
  }

  void _retryLoading() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _listenToProductsWithFallback();
  }

  void _openFilterSheet() {
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
    context.watch<AuthProvider>();
    context.watch<BottomNavProvider>();
    context.watch<ActiveLeasesProvider>();
    context.watch<ReviewsProvider>();
    context.watch<CategoryService>();
    final connectivity = context.watch<ConnectivityService>();
    final currentUser = context.watch<AuthProvider>().currentUser;
    final allProducts = filteredProducts;
    final visibleProducts = allProducts.take(visibleCount).toList();

    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                color: theme.colorScheme.surface,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      resetPagination();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Поиск',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.filter_list, color: theme.primaryColor),
                      onPressed: _openFilterSheet,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Нет соединения с интернетом',
              style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              'Проверьте подключение и попробуйте снова',
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.4)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retryLoading,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      );
    }
    if (allProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Ничего не найдено',
              style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить параметры поиска',
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.4)),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
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
    );
  }
}