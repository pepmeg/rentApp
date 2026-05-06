import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/admin_models/report.dart';
import '../../models/user.dart';
import '../../data/product_data.dart';
import '../../provider/admin_provider.dart';
import '../../provider/AuthProvider.dart';
import '../../utils/colors.dart';
import '../../utils/pagination.dart';
import '../productScreen.dart';
import '../person.dart';

class AdminReportsTab extends StatefulWidget {
  final ReportTargetType? initialTargetType;
  const AdminReportsTab({super.key, this.initialTargetType});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> with PaginationMixin {
  ReportTargetType? _filterTargetType;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filterTargetType = widget.initialTargetType;
  }

  @override
  int get paginationBatchSize => 10;

  @override
  List<dynamic> get paginationItems => _filteredReports;

  List<Report> get _filteredReports {
    final admin = context.read<AdminProvider>();
    var reports = admin.reports.where((r) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!r.reason.toLowerCase().contains(query) &&
            !(r.productId?.toString().contains(query) ?? false) &&
            !(r.targetUserId?.toString().contains(query) ?? false)) {
          return false;
        }
      }
      if (_filterTargetType != null && r.targetType != _filterTargetType) {
        return false;
      }
      return true;
    }).toList();
    reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reports;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final allItems = _filteredReports;
    final visibleItems = allItems.take(visibleCount).toList();
    final currentUserId = auth.currentUser?.id;

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
                hintText: 'Поиск жалоб',
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
              _buildFilterChip('Все', _filterTargetType == null, () {
                setState(() => _filterTargetType = null);
                resetPagination();
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Товары', _filterTargetType == ReportTargetType.product, () {
                setState(() => _filterTargetType = ReportTargetType.product);
                resetPagination();
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Пользователи', _filterTargetType == ReportTargetType.user, () {
                setState(() => _filterTargetType = ReportTargetType.user);
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
              final report = visibleItems[index];
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

                  return Stack(
                    children: [
                      Card(
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
                            _formatDate(report.createdAt),
                            style: TextStyle(fontSize: 12, color: AppColors.oliveGray.withOpacity(0.5)),
                          ),
                          onTap: () {
                            if (currentUserId != null && !report.readByUserIds.contains(currentUserId)) {
                              context.read<AdminProvider>().markReportAsRead(report.id, currentUserId);
                            }
                            if (isProductReport && report.productId != null) {
                              final product = ProductData.getProductById(report.productId!);
                              if (product != null) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ProductScreen(product: product)));
                              }
                            } else if (!isProductReport && report.targetUserId != null) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => Profile(userId: report.targetUserId)));
                            }
                          },
                        ),
                      ),
                      if (currentUserId != null && !report.readByUserIds.contains(currentUserId))
                        Positioned(
                          top: 12,
                          right: 20,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.copper,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.copper,
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final dateFormat = (date.year == now.year) ? 'dd.MM' : 'dd.MM.yyyy';
    return DateFormat(dateFormat).format(date);
  }
}