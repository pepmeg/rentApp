import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin_models/report.dart';
import '../../pages/admin/admin_screen.dart';
import '../../provider/admin_provider.dart';
import '../../provider/AuthProvider.dart';
import '../../utils/colors.dart';

class AdminDashboardWidget extends StatefulWidget {
  const AdminDashboardWidget({super.key});

  @override
  State<AdminDashboardWidget> createState() => _AdminDashboardWidgetState();
}

class _AdminDashboardWidgetState extends State<AdminDashboardWidget> {
  @override
  void initState() {
    super.initState();
    context.read<AdminProvider>().loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final auth = context.read<AuthProvider>();
    final bool isAdmin = auth.isAdmin;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAdmin) ...[
            _buildSectionTitle('Товары'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Все',
                    value: admin.totalProducts.toString(),
                    icon: Icons.shopping_bag_rounded,
                    color: AppColors.lightGreen,
                    onTap: () => _openModerationTab(context, 0, productStatusFilter: null),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Скрытые',
                    value: admin.hiddenProducts.toString(),
                    icon: Icons.visibility_off_rounded,
                    color: AppColors.macaroniCheese,
                    onTap: () => _openModerationTab(context, 0, productStatusFilter: 'hidden'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Заблок.',
                    value: admin.blockedProducts.toString(),
                    icon: Icons.block_rounded,
                    color: Colors.redAccent,
                    onTap: () => _openModerationTab(context, 0, productStatusFilter: 'blocked'),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          _buildSectionTitle('Жалобы'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Всего',
                  value: admin.totalReports.toString(),
                  icon: Icons.report_problem_rounded,
                  color: AppColors.copper,
                  onTap: () => _openModerationTab(
                    context,
                    isAdmin ? 1 : 0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricCard(
                  title: 'На товары',
                  value: admin.reportsOnProductsCount.toString(),
                  icon: Icons.shopping_bag_rounded,
                  color: AppColors.lightGreen,
                  onTap: () => _openModerationTab(
                    context,
                    isAdmin ? 1 : 0,
                    reportFilterType: ReportTargetType.product,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricCard(
                  title: 'На польз.',
                  value: admin.reportsOnUsersCount.toString(),
                  icon: Icons.person,
                  color: AppColors.oliveGray,
                  onTap: () => _openModerationTab(
                    context,
                    isAdmin ? 1 : 0,
                    reportFilterType: ReportTargetType.user,
                  ),
                ),
              ),
            ],
          ),

          if (isAdmin) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('Пользователи'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Активные',
                    value: admin.activeUsers.toString(),
                    icon: Icons.people_rounded,
                    color: AppColors.oliveGray,
                    onTap: () => _openModerationTab(context, 2),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Заблок.',
                    value: admin.blockedUsersCount.toString(),
                    icon: Icons.block_rounded,
                    color: Colors.redAccent,
                    onTap: () => _openModerationTab(context, 2, showBlockedUsers: true),
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.oliveGray.withOpacity(0.8),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: AppColors.whiteAntique,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: AppColors.oliveGray.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.oliveGray,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.oliveGray.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openModerationTab(
      BuildContext context,
      int tabIndex, {
        bool? showBlockedUsers,
        ReportTargetType? reportFilterType,
        String? productStatusFilter,
      }) {
    final auth = context.read<AuthProvider>();
    final bool isAdmin = auth.isAdmin;
    final bool isSupport = auth.isSupport;

    final maxTabs = isAdmin ? 4 : 2;
    if (tabIndex < 0 || tabIndex >= maxTabs) return;

    if (isSupport && (productStatusFilter != null || showBlockedUsers == true)) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminScreen(
          initialTabIndex: tabIndex,
          showBlockedUsers: showBlockedUsers,
          reportFilterType: reportFilterType,
          productStatusFilter: productStatusFilter,
        ),
      ),
    );
  }
}