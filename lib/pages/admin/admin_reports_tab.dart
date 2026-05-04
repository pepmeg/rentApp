import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/admin_provider.dart';
import '../../utils/colors.dart';

class AdminReportsTab extends StatelessWidget {
  const AdminReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final reports = admin.reports;

    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Card(
          color: AppColors.whiteAntique,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text('Товар #${report.productId}'),
            subtitle: Text('Причина: ${report.reason}'),
            trailing: Text(report.status.toString()),
          ),
        );
      },
    );
  }
}