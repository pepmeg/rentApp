import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../models/activeLease.dart';
import '../models/product.dart';
import '../provider/AuthProvider.dart';
import '../provider/activeLeasesProvider.dart';
import '../utils/pagination.dart';
import '../widgets/search_field.dart';
import '../widgets/userOrders_card.dart';
import 'add_edit_form.dart';
import 'productScreen.dart';

class UserOrders extends StatefulWidget {
  final String? ownerId;
  const UserOrders({super.key, this.ownerId});

  @override
  State<UserOrders> createState() => _UserOrdersState();
}

class _UserOrdersState extends State<UserOrders> with PaginationMixin {
  String searchQuery = '';
  bool _showActiveRents = false;
  List<Product> _allProducts = [];
  bool _isLoading = false;

  @override
  int get paginationBatchSize => 12;

  @override
  List<dynamic> get paginationItems => _filteredProducts;

  List<Product> get _filteredProducts {
    final leasesProvider = context.watch<ActiveLeasesProvider>();
    final targetId = widget.ownerId ?? context.read<AuthProvider>().currentUser?.uid;
    var list = _allProducts;

    if (_showActiveRents && targetId != null) {
      final activeLeaseProductIds = leasesProvider.leases
          .where((l) =>
      (l.status == LeaseStatus.active || l.status == LeaseStatus.pendingCompletion) &&
          l.ownerId == targetId)
          .map((l) => l.productId)
          .toSet();
      list = list.where((p) => activeLeaseProductIds.contains(p.id)).toList();
    }

    if (searchQuery.isNotEmpty) {
      list = list
          .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final targetId = widget.ownerId ?? context.read<AuthProvider>().currentUser?.uid;
      if (targetId != null) {
        _allProducts = await ProductService.getAllProducts(ownerId: targetId);
      } else {
        _allProducts = [];
      }
    } catch (e) {
      debugPrint('Ошибка загрузки товаров: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _openEditProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductForm(product: product)),
    );
    if (result == true) {
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final targetId = widget.ownerId ?? currentUser?.uid;
    final isOwner = targetId == currentUser?.uid;
    final allItems = _filteredProducts;
    final visibleItems = allItems.take(visibleCount).toList();
    final leasesProvider = context.watch<ActiveLeasesProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 24, color: theme.colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: SearchField(
                    hintText: 'Поиск...',
                    padding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                      resetPagination();
                    },
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
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.4),
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
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(height: 1, thickness: 1, color: theme.dividerColor),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                  : visibleItems.isEmpty
                  ? Center(
                child: Text(
                  _showActiveRents ? 'Нет активных аренд' : 'Нет объявлений',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              )
                  : ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: visibleItems.length,
                itemBuilder: (context, index) {
                  final product = visibleItems[index];
                  ActiveLease? activeLease;
                  if (_showActiveRents && isOwner) {
                    activeLease = leasesProvider.leases.cast<ActiveLease?>().firstWhere(
                          (l) =>
                      l != null &&
                          l.productId == product.id &&
                          (l.status == LeaseStatus.active || l.status == LeaseStatus.pendingCompletion) &&
                          l.ownerId == targetId,
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
                        MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
                      );
                    },
                  );
                },
              ),
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
}