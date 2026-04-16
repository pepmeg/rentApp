import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:untitled/data/product_data.dart';
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

  List<Product> get filteredProducts {
    return ProductData.searchProducts(searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final products = ProductData.getAllProducts();
    final filteredProducts = products.where((product) =>
        product.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
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
                          child: Text(item),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return FavoriteCard(
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
