import 'package:AppRent/widgets/profile_widget/profile_common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pages/active_leases.dart';
import '../../pages/edit_profile.dart';
import '../../pages/user_orders.dart';
import '../../pages/notifications.dart';
import '../../provider/AuthProvider.dart';
import '../../data/product_data.dart';
import '../../models/activeLease.dart';
import '../../provider/LeaseRequestProvider.dart';
import '../../provider/ReviewsProvider.dart';
import '../../provider/activeLeasesProvider.dart';
import '../../provider/basket_provider.dart';
import '../../provider/chat_provider.dart';
import '../../provider/favorite_provider.dart';
import '../../utils/avatar.dart';
import '../../utils/colors.dart';
import '../admin_widget/AdminDashboardWidget.dart';
import '../lease_card/lease_card.dart';
import '../../models/user.dart';

class ProfileOwn extends StatelessWidget {
  const ProfileOwn({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return const SizedBox.shrink();

    final leasesProvider = context.watch<ActiveLeasesProvider>();
    final leases = leasesProvider.getLeasesForUser(user.id);
    final totalOrders = leases.length;
    final activeOrders = leases.where((l) => l.status == LeaseStatus.active).length;

    final incomingCount = context.watch<LeaseRequestProvider>()
        .getIncomingRequests(user.id)
        .length;

    final userProductsCount = ProductData.products
        .where((p) => p.ownerId == user.id && p.moderationStatus != 'blocked')
        .length;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, incomingCount),
              const SizedBox(height: 30),
              ProfileUserInfo(
                user: user,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfile())),
              ),
              if (user.role == 'admin' || user.role == 'support') ...[
                const AdminDashboardWidget(),
              ],
              const SizedBox(height: 30),
              if (user.role == 'user') ...[
                _buildStats(context, user, totalOrders, activeOrders),
                const SizedBox(height: 15),
                ProfileAdsButton(
                  count: userProductsCount,
                  label: 'Мои объявления',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserOrders())),
                ),
                const SizedBox(height: 20),
                _buildActiveLeasesSection(context, leases),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int incomingCount) {
    final user = context.read<AuthProvider>().currentUser;
    return Row(
      children: [
        const Text('Профиль',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
        const SizedBox(width: 10),
        const Spacer(),
        if (user?.role == 'user')
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 28, color: AppColors.oliveGray),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
              if (incomingCount > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.copper,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$incomingCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        GestureDetector(
          onTap: () => _showExitMenu(context),
          child: const Icon(Icons.more_vert, size: 30, color: AppColors.oliveGray),
        ),
      ],
    );
  }

  void _showExitMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        decoration: const BoxDecoration(
          color: AppColors.whiteAntique,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.oliveGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuOption(
              icon: Icons.logout,
              label: 'Выйти',
              color: AppColors.oliveGray,
              onTap: () {
                Navigator.pop(ctx);
                _logoutAndNavigate(context);
              },
            ),
            const Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.spaceCream),
            _buildMenuOption(
              icon: Icons.delete_forever_outlined,
              label: 'Удалить аккаунт',
              color: Colors.redAccent,
              isDestructive: true,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteAccount(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required Color color,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logoutAndNavigate(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    await auth.logout(chatProvider: chatProvider);
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _confirmDeleteAccount(BuildContext context) {
    final userId = context.read<AuthProvider>().currentUser!.id;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.whiteAntique,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 12),
            const Text('Удалить аккаунт?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
          ],
        ),
        content: const Text(
          'Это действие необратимо. Все ваши данные будут удалены.',
          style: TextStyle(fontSize: 15, color: AppColors.oliveGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(color: AppColors.oliveGray, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ProductData.deleteProductsByOwner(userId);
              context.read<ChatProvider>().deleteChatsForUser(userId);
              context.read<ActiveLeasesProvider>().deleteLeasesForUser(userId);
              context.read<LeaseRequestProvider>().deleteRequestsForUser(userId);
              context.read<BasketProvider>().clearCartForUser(userId);
              context.read<ReviewsProvider>().deleteReviewsByUser(userId);
              context.read<FavoriteProvider>().clearFavoritesForUser(userId);
              final auth = context.read<AuthProvider>();
              await auth.deleteAccount();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Удалить', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, UserModel user, int totalOrders, int activeOrders) {
    final reviewsProvider = context.watch<ReviewsProvider>();
    final userProducts = ProductData.products.where((p) => p.ownerId == user.id).toList();
    final userReviews = reviewsProvider.reviews.where((r) => userProducts.any((p) => p.id == r.productId)).toList();
    final double avgRating = userReviews.isEmpty
        ? 0.0
        : userReviews.map((r) => r.rating).reduce((a, b) => a + b) / userReviews.length;
    final String ratingText = userReviews.isEmpty ? '0' : avgRating.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.whiteAntique,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn('$totalOrders', 'Аренды'),
          _buildStatColumn('$activeOrders', 'Активных'),
          _buildStatColumn(ratingText, 'Рейтинг'),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray)),
        ],
      ),
    );
  }

  Widget _buildActiveLeasesSection(BuildContext context, List leases) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Активные аренды',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: AppColors.oliveGray)),
            const Spacer(),
            if (leases.isNotEmpty)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveLeases())),
                child: Text('Показать все',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: AppColors.oliveGray.withOpacity(0.5))),
              ),
            if (leases.isNotEmpty) ...[
              const SizedBox(width: 3),
              const Icon(Icons.arrow_circle_right_sharp, size: 10, color: AppColors.oliveGray),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (leases.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: Text('Нет активных аренд',
                style: TextStyle(color: AppColors.oliveGray.withOpacity(0.5))),
          )
        else
          ...leases.take(3).map((lease) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LeaseCard(
              key: ValueKey('lease-${lease.productId}-${lease.status}'),
              lease: lease,
            ),
          )),
      ],
    );
  }
}