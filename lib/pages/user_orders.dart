import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/product_data.dart';
import '../models/product.dart';
import '../provider/AuthProvider.dart';
import '../utils/colors.dart';
import '../widgets/userOrders_card.dart';
import 'edit_product.dart';

class UserOrders extends StatefulWidget {
  const UserOrders({super.key});

  @override
  State<UserOrders> createState() => UserOrdersState();
}

class UserOrdersState extends State<UserOrders> {
  String searchQuery = '';

  List<Product> get filteredProducts {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return [];
    final userProducts = ProductData.products
        .where((p) => p.ownerId == user.id)
        .toList();
    if (searchQuery.isEmpty) return userProducts;
    return userProducts
        .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _openEditProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProduct(product: product)),
    );
    if (result == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 24, color: AppColors.oliveGray),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 5),
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
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return UserOrdersCard(
                    id: product.id,
                    name: product.name,
                    price: product.price,
                    location: product.location,
                    images: product.images,
                    createdAt: product.createdAt,
                    onEdit: () => _openEditProduct(product),
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