import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin_models/report.dart';
import '../../provider/AuthProvider.dart';
import 'admin_products_tab.dart';
import 'admin_reports_tab.dart';
import 'admin_users_tab.dart';
import 'admin_chats_tab.dart';

class AdminScreen extends StatefulWidget {
  final int initialTabIndex;
  final bool? showBlockedUsers;
  final ReportTargetType? reportFilterType;
  final String? productStatusFilter;

  const AdminScreen({
    super.key,
    this.initialTabIndex = 0,
    this.showBlockedUsers,
    this.reportFilterType,
    this.productStatusFilter,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final tabCount = auth.isAdmin ? 4 : 2;

    if (_tabController == null || _tabController!.length != tabCount) {
      _tabController?.dispose();
      _tabController = TabController(
        length: tabCount,
        vsync: this,
        animationDuration: const Duration(milliseconds: 500),
        initialIndex: widget.initialTabIndex.clamp(0, tabCount - 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin && !auth.isSupport) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);

    final List<Widget> tabs = [];
    final List<Widget> tabViews = [];

    if (auth.isAdmin) {
      tabs.addAll([
        const Tab(text: 'Товары'),
        const Tab(text: 'Жалобы'),
        const Tab(text: 'Пользователи'),
        const Tab(text: 'Чаты'),
      ]);
      tabViews.addAll([
        AdminProductsTab(initialStatusFilter: widget.productStatusFilter),
        AdminReportsTab(initialTargetType: widget.reportFilterType),
        AdminUsersTab(initialShowBlocked: widget.showBlockedUsers ?? false),
        AdminChatsTab(),
      ]);
    } else if (auth.isSupport) {
      tabs.addAll([
        const Tab(text: 'Жалобы'),
        const Tab(text: 'Чаты'),
      ]);
      tabViews.addAll([
        AdminReportsTab(initialTargetType: widget.reportFilterType),
        AdminChatsTab(),
      ]);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Модерация', style: TextStyle(color: theme.colorScheme.onSurface)),
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        bottom: TabBar(
          controller: _tabController,
          labelPadding: const EdgeInsets.symmetric(horizontal: 2),
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
          indicatorColor: theme.primaryColor,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabViews,
      ),
    );
  }
}