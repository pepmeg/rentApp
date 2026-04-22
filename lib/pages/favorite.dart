import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/data/product_data.dart';
import 'package:untitled/provider/favorite_provider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/favorite_card.dart';
import 'package:untitled/widgets/category.dart';
import '../models/product.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => FavoriteState();
}

class FavoriteState extends State<Favorite> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final allProducts = ProductData.getAllProducts();

    final favoriteProducts = allProducts
        .where((product) => favoriteProvider.isFavorite(product.id))
        .toList();

    final filteredProducts = favoriteProducts
        .where((product) =>
        product.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    final Category category = Category();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          children: [
            Container(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Поиск...',
                  prefixIcon: Icon(Icons.search, color: AppColors.copper),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 15, horizontal: 20
                  ),
                ),
              ),
            ),
            SizedBox(height: 15),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: category.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lightGreen,
                            foregroundColor: AppColors.oliveGray,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(15),
                            ),
                            elevation: 2,
                            padding: const EdgeInsetsGeometry.symmetric(horizontal: 16, vertical: 8)
                          ),
                          child: Text(
                            item,
                          style: TextStyle(fontWeight: FontWeight.normal,fontSize: 14),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 20),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return FavoriteCard(
                    id: product.id,
                    name: product.name,
                    price: product.price,
                    location: product.location,
                    image: product.image,
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
