import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../pages/productScreen.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/admin_provider.dart';
import '../../utils/colors.dart';
import '../../utils/form_fields.dart';
import '../../utils/pagination.dart';

class AdminProductsTab extends StatefulWidget {
  final String? initialStatusFilter;
  const AdminProductsTab({super.key, this.initialStatusFilter});

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> with PaginationMixin {
  String _searchQuery = '';
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatusFilter;
  }

  @override
  int get paginationBatchSize => 12;

  @override
  List<dynamic> get paginationItems => _filteredProducts;

  List<Product> get _filteredProducts {
    final admin = context.read<AdminProvider>();
    var products = admin.getAllProducts().toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      products = products.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.price.toString().contains(query) ||
            p.location.toLowerCase().contains(query);
      }).toList();
    }

    if (_statusFilter != null) {
      products = products.where((p) => p.moderationStatus == _statusFilter).toList();
    }

    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return products;
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _filteredProducts;
    final visibleItems = allItems.take(visibleCount).toList();
    final auth = context.watch<AuthProvider>();
    final admin = context.watch<AdminProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
                resetPagination();
              },
              decoration: InputDecoration(
                hintText: 'Поиск товаров',
                hintStyle: TextStyle(color: AppColors.oliveGray.withOpacity(0.5), fontSize: 16),
                prefixIcon: Icon(Icons.search, color: AppColors.copper),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: AppColors.oliveGray.withOpacity(0.5)),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    resetPagination();
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              _buildFilterChip('Все', _statusFilter == null, () {
                setState(() => _statusFilter = null);
                resetPagination();
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Скрытые', _statusFilter == 'hidden', () {
                setState(() => _statusFilter = 'hidden');
                resetPagination();
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Заблокированные', _statusFilter == 'blocked', () {
                setState(() => _statusFilter = 'blocked');
                resetPagination();
              }),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: visibleItems.length,
            itemBuilder: (context, index) {
              final product = visibleItems[index];
              final ownerFuture = auth.getUserById(product.ownerId);

              return Card(
                color: AppColors.whiteAntique,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: FutureBuilder(
                      future: ownerFuture,
                      builder: (context, snapshot) {
                        final ownerName = (snapshot.data != null)
                            ? '${snapshot.data!.firstName} ${snapshot.data!.lastName}'
                            : 'Нет данных';

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildProductImage(product, 72),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.oliveGray,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _statusColor(product.moderationStatus).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _status(product.moderationStatus),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _statusColor(product.moderationStatus),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${product.price} ₽${product.isPricePerHour ? '/час' : '/день'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.oliveGray.withOpacity(0.9),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: AppColors.oliveGray.withOpacity(0.6)),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          product.location,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.oliveGray.withOpacity(0.7),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Владелец: $ownerName',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.oliveGray.withOpacity(0.6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (auth.isAdmin)
                              AppPopupMenuButton<String>(
                                backgroundColor: AppColors.spaceCream,
                                onSelected: (action) => _performAction(admin, product.id, action),
                                items: _getAvailableActions(product.moderationStatus),
                              )
                            else
                              const SizedBox(width: 22),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(color: AppColors.copper)),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor: selected ? AppColors.copper.withOpacity(0.2) : AppColors.spaceCream,
        labelStyle: TextStyle(
          color: selected ? AppColors.copper : AppColors.oliveGray,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product, double size) {
    if (product.images.isNotEmpty) {
      final path = product.images.first;
      if (path.startsWith('assets/')) {
        return Image.asset(path, width: size, height: size, fit: BoxFit.cover);
      } else {
        return Image.file(File(path), width: size, height: size, fit: BoxFit.cover);
      }
    }
    return Container(
      width: size,
      height: size,
      color: AppColors.oliveGray.withOpacity(0.1),
      child: Icon(Icons.image, color: AppColors.oliveGray.withOpacity(0.5), size: 28),
    );
  }

  String _status(String status) {
    switch (status) {
      case 'active':
        return 'Активен';
      case 'hidden':
        return 'Скрыт';
      case 'blocked':
        return 'Заблокирован';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'hidden':
        return AppColors.macaroniCheese;
      case 'blocked':
        return AppColors.copper;
      default:
        return AppColors.oliveGray;
    }
  }

  List<PopupMenuEntry<String>> _getAvailableActions(String currentStatus) {
    final items = <PopupMenuEntry<String>>[];
    if (currentStatus == 'active') {
      items.add(const PopupMenuItem(value: 'hide', child: Text('Скрыть')));
      items.add(const PopupMenuItem(value: 'block', child: Text('Заблокировать')));
    } else if (currentStatus == 'hidden' || currentStatus == 'blocked') {
      items.add(const PopupMenuItem(value: 'unhide', child: Text('Восстановить')));
      if (currentStatus != 'blocked') {
        items.add(const PopupMenuItem(value: 'block', child: Text('Заблокировать')));
      }
    }
    return items;
  }

  void _performAction(AdminProvider admin, int productId, String action) {
    switch (action) {
      case 'hide':
        admin.hideProduct(productId, 0, 'Скрыто администратором');
        break;
      case 'unhide':
        admin.unhideProduct(productId, 0, 'Восстановлено администратором');
        break;
      case 'block':
        admin.blockProduct(productId, 0, 'Заблокировано');
        break;
    }
  }
}