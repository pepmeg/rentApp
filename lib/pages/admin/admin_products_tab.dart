import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../pages/productScreen.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/admin_provider.dart';
import '../../services/product_service.dart';
import '../../utils/form_fields.dart';
import '../../utils/pagination.dart';
import '../../widgets/product_image.dart';

class AdminProductsTab extends StatefulWidget {
  final String? initialStatusFilter;
  const AdminProductsTab({super.key, this.initialStatusFilter});

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> with PaginationMixin {
  String _searchQuery = '';
  String? _statusFilter;
  List<Product> _allProducts = [];
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatusFilter;
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      _allProducts = await ProductService.getAllProducts(includeAll: true);
    } catch (e) {
      debugPrint('Ошибка загрузки товаров: $e');
    }
    setState(() => _isLoadingProducts = false);
  }

  @override
  int get paginationBatchSize => 12;

  @override
  List<dynamic> get paginationItems => _filteredProducts;

  List<Product> get _filteredProducts {
    var products = _allProducts;

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
  Set<String> _collectOwnerIds(List<Product> products) {
    final Set<String> ids = {};
    for (final p in products) {
      if (p.ownerId.isNotEmpty) ids.add(p.ownerId);
    }
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _filteredProducts;
    final visibleItems = allItems.take(visibleCount).toList();
    final auth = context.watch<AuthProvider>();
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final ownerIds = _collectOwnerIds(visibleItems);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              color: theme.colorScheme.surface,
              child: TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  resetPagination();
                },
                decoration: InputDecoration(
                  hintText: 'Поиск товаров',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 16),
                  prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              _buildFilterChip(theme, 'Все', _statusFilter == null, () {
                setState(() => _statusFilter = null);
                resetPagination();
              }),
              const SizedBox(width: 8),
              _buildFilterChip(theme, 'Скрытые', _statusFilter == 'hidden', () {
                setState(() => _statusFilter = 'hidden');
                resetPagination();
              }),
              const SizedBox(width: 8),
              _buildFilterChip(theme, 'Заблокированные', _statusFilter == 'blocked', () {
                setState(() => _statusFilter = 'blocked');
                resetPagination();
              }),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingProducts
              ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
              : FutureBuilder(
            future: ownerIds.isEmpty
                ? Future.value(null)
                : auth.preloadUsers(ownerIds.toList()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && visibleItems.isNotEmpty) {
                final cachedCount = ownerIds.where((id) => auth.getCachedUser(id) != null).length;
                if (cachedCount == 0) {
                  return Center(child: CircularProgressIndicator(color: theme.primaryColor));
                }
              }
              return ListView.builder(
                controller: scrollController,
                itemCount: visibleItems.length,
                itemBuilder: (context, index) {
                  final product = visibleItems[index];
                  final owner = auth.getCachedUser(product.ownerId);
                  final ownerName = (owner != null)
                      ? '${owner.firstName} ${owner.lastName}'
                      : 'Нет данных';
                  return Card(
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildProductImage(product, 72, theme),
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
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _statusColor(product.moderationStatus, theme).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _status(product.moderationStatus),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _statusColor(product.moderationStatus, theme),
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
                                      color: theme.colorScheme.onSurface.withOpacity(0.9),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          product.location,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (auth.isAdmin)
                              AppPopupMenuButton<String>(
                                backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                                onSelected: (action) => _performAction(admin, product.id, action),
                                items: _getAvailableActions(product.moderationStatus),
                              )
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
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
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor: selected ? theme.primaryColor.withOpacity(0.1) : (theme.cardTheme.color ?? theme.colorScheme.surface),
        labelStyle: TextStyle(
          color: selected ? theme.primaryColor : theme.colorScheme.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product, double size, ThemeData theme) {
    return ProductImage(
      images: product.images,
      width: size,
      height: size,
      backgroundColor: theme.colorScheme.background,
      cacheUrls: true,
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

  Color _statusColor(String status, ThemeData theme) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'hidden':
        return Colors.orange;
      case 'blocked':
        return theme.primaryColor;
      default:
        return theme.colorScheme.onSurface;
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

  void _performAction(AdminProvider admin, String productId, String action) async {
    final auth = context.read<AuthProvider>();
    final adminId = auth.currentUser?.uid ?? '0';
    switch (action) {
      case 'hide':
        await admin.hideProduct(productId, adminId, 'Скрыто администратором');
        break;
      case 'unhide':
        await admin.unhideProduct(productId, adminId, 'Восстановлено администратором');
        break;
      case 'block':
        await admin.blockProduct(productId, adminId, 'Заблокировано');
        break;
    }
    await _loadProducts();
  }
}