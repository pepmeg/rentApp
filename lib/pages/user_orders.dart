import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/product_data.dart';
import '../models/activeLease.dart';
import '../models/product.dart';
import '../provider/AuthProvider.dart';
import '../provider/activeLeasesProvider.dart';
import '../utils/colors.dart';
import '../widgets/userOrders_card.dart';
import 'edit_product.dart';

class UserOrders extends StatefulWidget {
  final int? ownerId;
  const UserOrders({super.key, this.ownerId});

  @override
  State<UserOrders> createState() => UserOrdersState();
}

class UserOrdersState extends State<UserOrders> {
  String searchQuery = '';
  bool _showActiveRents = false;

  List<Product> get filteredProducts {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return [];

    final targetId = widget.ownerId ?? user.id;
    var userProducts = ProductData.products
        .where((p) => p.ownerId == targetId)
        .toList();

    if (_showActiveRents) {
      final activeLeases = context.read<ActiveLeasesProvider>()
          .leases
          .where((l) => l.status == LeaseStatus.active)
          .toList();
      final activeProductIds = activeLeases.map((l) => l.productId).toSet();
      userProducts = userProducts.where((p) => activeProductIds.contains(p.id)).toList();
    }

    if (searchQuery.isNotEmpty) {
      userProducts = userProducts
          .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return userProducts;
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
    final currentUser = context.read<AuthProvider>().currentUser;
    final targetId = widget.ownerId ?? currentUser?.id;
    final isOwner = targetId == currentUser?.id;

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
            if (isOwner) ...[
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showActiveRents = false),
                      child: Text(
                        'Все',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: !_showActiveRents
                              ? AppColors.oliveGray
                              : AppColors.oliveGray.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showActiveRents = true),
                      child: Text(
                        'Активные объявления',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _showActiveRents
                              ? AppColors.oliveGray
                              : AppColors.oliveGray.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.oliveGray.withOpacity(0.2),
              ),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  ActiveLease? activeLease;
                  if (_showActiveRents && isOwner) {
                    final leases = context.read<ActiveLeasesProvider>().leases;
                    activeLease = leases.cast<ActiveLease?>().firstWhere(
                          (l) => l!.productId == product.id && l.status == LeaseStatus.active,
                      orElse: () => null,
                    );
                  }
                  return UserOrdersCard(
                    id: product.id,
                    name: product.name,
                    price: product.price,
                    location: product.location,
                    images: product.images,
                    createdAt: product.createdAt,
                    activeLease: activeLease,
                    isOwner: isOwner,
                    onEdit: isOwner ? () => _openEditProduct(product) : () {},
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