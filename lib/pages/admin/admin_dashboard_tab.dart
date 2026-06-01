import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/admin_provider.dart';

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
        _buildMetricCard(theme, 'Товаров', admin.totalProducts.toString(), Icons.shopping_bag),
        _buildMetricCard(theme, 'Жалоб', admin.totalReports.toString(), Icons.report),
        _buildMetricCard(theme, 'Скрыто', admin.hiddenProducts.toString(), Icons.visibility_off),
        _buildMetricCard(theme, 'Заблокировано', admin.blockedProducts.toString(), Icons.block),
        _buildMetricCard(theme, 'Активных пользователей', admin.activeUsers.toString(), Icons.people),
        _buildMetricCard(theme, 'Заблокированных пользователей', admin.blockedUsersCount.toString(), Icons.block),
      ],
    );
  }

  Widget _buildMetricCard(ThemeData theme, String title, String value, IconData icon) {
    return Card(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: theme.primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          Text(
            title,
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}