import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/AuthProvider.dart';
import '../../utils/colors.dart';
import 'admin_products_tab.dart';
import 'admin_reports_tab.dart';
import 'admin_users_tab.dart';
import 'admin_chats_tab.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin && !auth.isSupport) {
      return const SizedBox.shrink();
    }

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
        const AdminProductsTab(),
        const AdminReportsTab(),
        const AdminUsersTab(),
        const AdminChatsTab(),
      ]);
    } else if (auth.isSupport) {
      tabs.addAll([
        const Tab(text: 'Жалобы'),
        const Tab(text: 'Чаты'),
      ]);
      tabViews.addAll([
        const AdminReportsTab(),
        const AdminChatsTab(),
      ]);
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.spaceCream,
        appBar: AppBar(
          title: const Text('Модерация', style: TextStyle(color: AppColors.oliveGray)),
          backgroundColor: AppColors.whiteAntique,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.oliveGray),
          bottom: TabBar(
            labelColor: AppColors.copper,
            unselectedLabelColor: AppColors.oliveGray.withOpacity(0.5),
            indicatorColor: AppColors.copper,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
            tabs: tabs,
          ),
        ),
        body: TabBarView(children: tabViews),
      ),
    );
  }
}