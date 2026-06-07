import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin_models/report.dart';
import '../../pages/admin/admin_screen.dart';
import '../../provider/admin_provider.dart';
import '../../provider/AuthProvider.dart';
import '../../widgets/stat_card.dart';

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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAdmin) ...[
            _buildSectionTitle(theme, 'Товары'),
            const SizedBox(height: 6),
            Row(
              children: [
                StatCard(
                  value: admin.totalProducts.toString(),
                  label: 'Все',
                  icon: Icons.shopping_bag_rounded,
                  iconColor: theme.primaryColor,
                  compact: true,
                  onTap: () => _openModerationTab(context, 0, productStatusFilter: null),
                ),
                const SizedBox(width: 6),
                StatCard(
                  value: admin.hiddenProducts.toString(),
                  label: 'Скрытые',
                  icon: Icons.visibility_off_rounded,
                  iconColor: Colors.orange.shade300,
                  compact: true,
                  onTap: () => _openModerationTab(context, 0, productStatusFilter: 'hidden'),
                ),
                const SizedBox(width: 6),
                StatCard(
                  value: admin.blockedProducts.toString(),
                  label: 'Заблок.',
                  icon: Icons.block_rounded,
                  iconColor: Colors.redAccent,
                  compact: true,
                  onTap: () => _openModerationTab(context, 0, productStatusFilter: 'blocked'),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          _buildSectionTitle(theme, 'Жалобы'),
          const SizedBox(height: 6),
          Row(
            children: [
              StatCard(
                value: admin.totalReports.toString(),
                label: 'Всего',
                icon: Icons.report_problem_rounded,
                iconColor: theme.primaryColor,
                compact: true,
                onTap: () => _openModerationTab(context, isAdmin ? 1 : 0),
              ),
              const SizedBox(width: 6),
              StatCard(
                value: admin.reportsOnProductsCount.toString(),
                label: 'На товары',
                icon: Icons.shopping_bag_rounded,
                iconColor: theme.primaryColor.withOpacity(0.7),
                compact: true,
                onTap: () => _openModerationTab(
                  context,
                  isAdmin ? 1 : 0,
                  reportFilterType: ReportTargetType.product,
                ),
              ),
              const SizedBox(width: 6),
              StatCard(
                value: admin.reportsOnUsersCount.toString(),
                label: 'На польз.',
                icon: Icons.person,
                iconColor: theme.colorScheme.onSurface,
                compact: true,
                onTap: () => _openModerationTab(
                  context,
                  isAdmin ? 1 : 0,
                  reportFilterType: ReportTargetType.user,
                ),
              ),
            ],
          ),

          if (isAdmin) ...[
            const SizedBox(height: 16),
            _buildSectionTitle(theme, 'Пользователи'),
            const SizedBox(height: 6),
            Row(
              children: [
                StatCard(
                  value: admin.activeUsers.toString(),
                  label: 'Активные',
                  icon: Icons.people_rounded,
                  iconColor: theme.colorScheme.onSurface,
                  compact: true,
                  onTap: () => _openModerationTab(context, 2),
                ),
                const SizedBox(width: 6),
                StatCard(
                  value: admin.blockedUsersCount.toString(),
                  label: 'Заблок.',
                  icon: Icons.block_rounded,
                  iconColor: Colors.redAccent,
                  compact: true,
                  onTap: () => _openModerationTab(context, 2, showBlockedUsers: true),
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

  Widget _buildSectionTitle(ThemeData theme, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withOpacity(0.8),
        letterSpacing: 0.3,
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