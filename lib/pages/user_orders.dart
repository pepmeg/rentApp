import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/product_data.dart';
import '../models/product.dart';
import '../utils/colors.dart';
import '../widgets/favorite_card.dart';

class UserOrders extends StatefulWidget {
  const UserOrders({super.key});

  @override
  State<UserOrders> createState() => UserOrdersState();
}

class UserOrdersState extends State<UserOrders> {
  String searchQuery = '';

  List<Product> get filteredProducts {
    return ProductData.searchProducts(searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final products = ProductData.getAllProducts();
    final filteredProducts = products
        .where(
          (product) =>
              product.name.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.only(left: 20, right: 20, top: 40),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    size: 24,
                    color: AppColors.oliveGray,
                  ),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Поиск...',
                        prefixIcon: Icon(Icons.search, color: AppColors.copper),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 20),
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
