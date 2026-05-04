import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/admin_provider.dart';
import '../../utils/colors.dart';

class AdminDashboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return GridView.count(
      crossAxisCount: 2,
      padding: EdgeInsets.all(16),
      children: [
        _buildMetricCard('Товаров', admin.totalProducts.toString(), Icons.shopping_bag),
        _buildMetricCard('Жалоб', admin.totalReports.toString(), Icons.report),
        _buildMetricCard('Скрыто', admin.hiddenProducts.toString(), Icons.visibility_off),
        _buildMetricCard('Заблокировано', admin.blockedProducts.toString(), Icons.block),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      color: AppColors.whiteAntique,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: AppColors.copper),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: AppColors.oliveGray.withOpacity(0.7))),
        ],
      ),
    );
  }
}