import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/product_data.dart';
import '../provider/AuthProvider.dart';
import '../provider/favorite_provider.dart';
import '../utils/colors.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/favorite_card.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => FavoriteState();
}

class FavoriteState extends State<Favorite> {
  String searchQuery = '';
  String? filterCategory;
  String? filterSubcategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !context.read<AuthProvider>().isUser) {
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<FavoriteProvider>().loadFavoritesForUser(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = context.watch<FavoriteProvider>();
    final allProducts = ProductData.getAllProducts();
    final user = context.watch<AuthProvider>().currentUser;

    var favoriteProducts = allProducts
        .where((product) => user != null && favoriteProvider.isFavorite(user.id, product.id))
        .where((product) => product.moderationStatus == 'active')
        .toList();

    if (filterCategory != null) {
      favoriteProducts = favoriteProducts
          .where((p) => p.category == filterCategory)
          .toList();
      if (filterSubcategory != null) {
        favoriteProducts = favoriteProducts
            .where((p) => p.subcategory == filterSubcategory)
            .toList();
      }
    }

    if (searchQuery.isNotEmpty) {
      favoriteProducts = favoriteProducts
          .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Поиск',
                  hintStyle: TextStyle(color: AppColors.oliveGray.withOpacity(0.5), fontSize: 16),
                  prefixIcon: Icon(Icons.search, color: AppColors.copper),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerLeft,
              child: CategoryFilterBar(
                onFilterChanged: (category, subcategory) {
                  setState(() {
                    filterCategory = category;
                    filterSubcategory = subcategory;
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: favoriteProducts.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: AppColors.oliveGray.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'Нет избранных товаров',
                      style: TextStyle(fontSize: 18, color: AppColors.oliveGray.withOpacity(0.5)),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: favoriteProducts.length,
                itemBuilder: (context, index) {
                  final product = favoriteProducts[index];
                  return FavoriteCard(
                    id: product.id,
                    name: product.name,
                    price: product.price,
                    location: product.location,
                    images: product.images,
                    isPricePerHour: product.isPricePerHour,
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