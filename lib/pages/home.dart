import 'package:AppRent/pages/productScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/product_data.dart';
import '../models/activeLease.dart';
import '../models/product.dart';
import '../provider/activeLeasesProvider.dart';
import '../utils/colors.dart';
import '../utils/pagination.dart';
import '../widgets/product_card.dart';
import '../widgets/category_filter.dart';
import '../provider/ReviewsProvider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}


class HomeState extends State<Home> with PaginationMixin {
  String searchQuery = '';
  String? selectedCategory;
  String? selectedSubcategory;
  int? minPrice;
  int? maxPrice;
  String? brandFilter;
  String? regionFilter;
  String? cityFilter;
  String? sortMode;

  @override
  int get paginationBatchSize => 8;

  @override
  List<dynamic> get paginationItems => filteredProducts;

  List<Product> get filteredProducts {
    var list = ProductData.getAllProducts();

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      list = list.where((p) => p.category == selectedCategory).toList();
    }
    if (selectedSubcategory != null && selectedSubcategory!.isNotEmpty) {
      list = list.where((p) => p.subcategory == selectedSubcategory).toList();
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

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CategoryFilterSheet(
        initialCategory: selectedCategory,
        initialSubcategory: selectedSubcategory,
        initialMinPrice: minPrice,
        initialMaxPrice: maxPrice,
        initialBrand: brandFilter,
        initialRegion: regionFilter,
        initialCity: cityFilter,
        initialSort: sortMode,
        onApply: (cat, sub, minP, maxP, brand, region, city, sort) {
          setState(() {
            selectedCategory = cat;
            selectedSubcategory = sub;
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
    final allProducts = filteredProducts;
    final visibleProducts = allProducts.take(visibleCount).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    resetPagination();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Поиск',
                  hintStyle: TextStyle(color: AppColors.oliveGray.withOpacity(0.5), fontSize: 16),
                  prefixIcon: Icon(Icons.search, color: AppColors.copper),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.filter_list, color: AppColors.copper),
                    onPressed: _openFilterSheet,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: allProducts.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: AppColors.oliveGray.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'Ничего не найдено',
                      style: TextStyle(fontSize: 18, color: AppColors.oliveGray.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Попробуйте изменить параметры поиска',
                      style: TextStyle(fontSize: 14, color: AppColors.oliveGray.withOpacity(0.4)),
                    ),
                  ],
                ),
              )
                  : GridView.builder(
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
                    id: product.id,
                    name: product.name,
                    price: product.price,
                    location: product.location,
                    images: product.images,
                    isPricePerHour: product.isPricePerHour,
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
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.copper),
                ),
              ),
          ],
        ),
      ),
    );
  }
}