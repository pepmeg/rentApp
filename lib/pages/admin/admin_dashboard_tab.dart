import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/admin_provider.dart';
import '../../widgets/stat_card.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      children: [
        StatCard(
          value: admin.totalProducts.toString(),
          label: 'Товаров',
          icon: Icons.shopping_bag,
        ),
        StatCard(
          value: admin.totalReports.toString(),
          label: 'Жалоб',
          icon: Icons.report,
        ),
        StatCard(
          value: admin.hiddenProducts.toString(),
          label: 'Скрыто',
          icon: Icons.visibility_off,
        ),
        StatCard(
          value: admin.blockedProducts.toString(),
          label: 'Заблокировано',
          icon: Icons.block,
        ),
        StatCard(
          value: admin.activeUsers.toString(),
          label: 'Активных пользователей',
          icon: Icons.people,
        ),
        StatCard(
          value: admin.blockedUsersCount.toString(),
          label: 'Заблокированных пользователей',
          icon: Icons.block,
        ),
      ],
    );
  }
}