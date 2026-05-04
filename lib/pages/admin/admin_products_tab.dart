import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/admin_provider.dart';
import '../../utils/colors.dart';

class AdminProductsTab extends StatefulWidget {
  const AdminProductsTab({super.key});

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final auth = context.watch<AuthProvider>();
    final products = admin.getAllProducts();

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          color: AppColors.whiteAntique,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text(product.name),
            subtitle: Text('Статус: ${product.moderationStatus}'),
            trailing: auth.isAdmin
                ? PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'hide') {
                  admin.hideProduct(product.id, 0, 'Скрыто администратором');
                } else if (action == 'unhide') {
                  admin.unhideProduct(product.id, 0, 'Восстановлено администратором');
                } else if (action == 'block') {
                  admin.blockProduct(product.id, 0, 'Заблокировано');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'hide', child: Text('Скрыть')),
                const PopupMenuItem(value: 'unhide', child: Text('Восстановить')),
                const PopupMenuItem(value: 'block', child: Text('Заблокировать')),
              ],
            )
                : null,
          ),
        );
      },
    );
  }
}