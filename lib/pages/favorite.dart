import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/data/product_data.dart';
import 'package:untitled/provider/favorite_provider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/favorite_card.dart';
import 'package:untitled/widgets/category_filter_bar.dart';
import '../models/product.dart';

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
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final allProducts = ProductData.getAllProducts();

    var favoriteProducts = allProducts
        .where((product) => favoriteProvider.isFavorite(product.id))
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
              child: ListView.builder(
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