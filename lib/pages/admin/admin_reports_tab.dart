import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/admin_models/report.dart';
import '../../models/user.dart';
import '../../data/product_data.dart';
import '../../provider/admin_provider.dart';
import '../../provider/AuthProvider.dart';
import '../../utils/colors.dart';
import '../productScreen.dart';
import '../person.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final auth = context.read<AuthProvider>();
    final allReports = admin.reports;

    final reports = _searchQuery.isEmpty
        ? allReports
        : allReports.where((r) {
      final query = _searchQuery.toLowerCase();
      return r.reason.toLowerCase().contains(query) ||
          (r.productId?.toString().contains(query) ?? false) ||
          (r.targetUserId?.toString().contains(query) ?? false);
    }).toList();

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
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Поиск жалоб',
                hintStyle: TextStyle(color: AppColors.oliveGray.withOpacity(0.5), fontSize: 16),
                prefixIcon: Icon(Icons.search, color: AppColors.copper),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: AppColors.oliveGray.withOpacity(0.5)),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
          ),
        ),
        // Список жалоб
        Expanded(
          child: ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final isProductReport = report.targetType == ReportTargetType.product;
              final targetLabel = isProductReport
                  ? 'На товар #${report.productId}'
                  : 'На пользователя #${report.targetUserId}';

              return FutureBuilder(
                future: Future.wait([
                  auth.getUserById(report.reporterId),
                  if (!isProductReport && report.targetUserId != null)
                    auth.getUserById(report.targetUserId!),
                ]),
                builder: (ctx, AsyncSnapshot<List<UserModel?>> snapshot) {
                  final reporter = snapshot.data?.isNotEmpty == true ? snapshot.data![0] : null;

                  return Card(
                    color: AppColors.whiteAntique,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isProductReport
                            ? AppColors.lightGreen
                            : AppColors.copper.withOpacity(0.2),
                        child: Icon(
                          isProductReport ? Icons.shopping_bag : Icons.person,
                          color: AppColors.oliveGray,
                        ),
                      ),
                      title: Text(
                        reporter != null
                            ? '${reporter.firstName} ${reporter.lastName}'
                            : 'Пользователь ${report.reporterId}',
                        style: TextStyle(color: AppColors.oliveGray),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            targetLabel,
                            style: TextStyle(fontSize: 13, color: AppColors.oliveGray.withOpacity(0.8)),
                          ),
                          Text(
                            report.reason,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.oliveGray.withOpacity(0.6)),
                          ),
                        ],
                      ),
                      trailing: Text(
                        DateFormat('dd.MM.yyyy').format(report.createdAt),
                        style: TextStyle(fontSize: 12, color: AppColors.oliveGray.withOpacity(0.5)),
                      ),
                      onTap: () {
                        if (isProductReport && report.productId != null) {
                          final product = ProductData.getProductById(report.productId!);
                          if (product != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen(product: product)));
                          }
                        } else if (!isProductReport && report.targetUserId != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => Profile(userId: report.targetUserId)));
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}