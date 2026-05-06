import 'package:AppRent/pages/productScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/product_data.dart';
import '../models/activeLease.dart';
import '../models/product.dart';
import '../provider/AuthProvider.dart';
import '../provider/activeLeasesProvider.dart';
import '../utils/colors.dart';
import '../utils/pagination.dart';
import '../widgets/userOrders_card.dart';
import 'edit_product.dart';

class UserOrders extends StatefulWidget {
  final int? ownerId;

  const UserOrders({super.key, this.ownerId});

  @override
  State<UserOrders> createState() => UserOrdersState();
}

class UserOrdersState extends State<UserOrders> with PaginationMixin {
  String searchQuery = '';
  bool _showActiveRents = false;

  @override
  int get paginationBatchSize => 12;

  @override
  List<dynamic> get paginationItems => filteredProducts;

  List<Product> get filteredProducts {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return [];

    final targetId = widget.ownerId ?? user.id;
    var userProducts = ProductData.products
        .where((p) => p.ownerId == targetId)
        .where((p) => p.moderationStatus != 'blocked')
        .toList();

    if (_showActiveRents) {
      final activeLeases = context
          .read<ActiveLeasesProvider>()
          .leases
          .where((l) => l.status == LeaseStatus.active)
          .toList();
      final activeProductIds = activeLeases.map((l) => l.productId).toSet();
      userProducts = userProducts
          .where((p) => activeProductIds.contains(p.id))
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      userProducts = userProducts
          .where(
            (p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    userProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
    final allItems = filteredProducts;
    final visibleItems = allItems.take(visibleCount).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 24,
                    color: AppColors.oliveGray,
                  ),
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
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                        resetPagination();
                      },
                      decoration: InputDecoration(
                        hintText: 'Поиск...',
                        prefixIcon: Icon(Icons.search, color: AppColors.copper),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
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
                      onTap: () {
                        setState(() => _showActiveRents = false);
                        resetPagination();
                      },
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
                      onTap: () {
                        setState(() => _showActiveRents = true);
                        resetPagination();
                      },
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
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: visibleItems.length,
                itemBuilder: (context, index) {
                  final product = visibleItems[index];
                  ActiveLease? activeLease;
                  if (_showActiveRents && isOwner) {
                    final leases = context.read<ActiveLeasesProvider>().leases;
                    activeLease = leases.cast<ActiveLease?>().firstWhere(
                      (l) =>
                          l!.productId == product.id &&
                          l.status == LeaseStatus.active,
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
                    isPricePerHour: product.isPricePerHour,
                    moderationStatus: product.moderationStatus,
                    onEdit: isOwner ? () => _openEditProduct(product) : () {},
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductScreen(product: product),
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
