import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pages/active_leases.dart';
import '../../pages/archived_leases.dart';
import '../../pages/edit_profile.dart';
import '../../pages/my_reviews_screen.dart';
import '../../pages/user_orders.dart';
import '../../pages/notifications.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/archived_leases_provider.dart';
import '../../provider/theme_provider.dart';
import '../../services/product_service.dart';
import '../../models/activeLease.dart';
import '../../provider/LeaseRequestProvider.dart';
import '../../provider/ReviewsProvider.dart';
import '../../provider/activeLeasesProvider.dart';
import '../../provider/basket_provider.dart';
import '../../provider/chat_provider.dart';
import '../../provider/favorite_provider.dart';
import '../admin_widget/AdminDashboardWidget.dart';
import '../lease_card/lease_card.dart';
import 'profile_common.dart';

class ProfileOwn extends StatefulWidget {
  const ProfileOwn({super.key});

  @override
  State<ProfileOwn> createState() => _ProfileOwnState();
}

class _ProfileOwnState extends State<ProfileOwn> {
  int _productCount = 0;
  double _rating = 0.0;
  bool _statsLoaded = false;
  late ReviewsProvider _reviewsProvider;
  late ArchivedLeasesProvider _archivedProvider;

  @override
  void initState() {
    super.initState();
    _reviewsProvider = context.read<ReviewsProvider>();
    _reviewsProvider.addListener(_onReviewsChanged);
    _archivedProvider = context.read<ArchivedLeasesProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        _archivedProvider.listenForUser(user.uid);
      }
    });
    _loadStats();
  }

  @override
  void dispose() {
    _reviewsProvider.removeListener(_onReviewsChanged);
    _archivedProvider.stopListening();
    super.dispose();
  }

  void _onReviewsChanged() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _loadRating(user.uid);
    }
  }

  Future<void> _loadStats() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    try {
      final products = await ProductService.getAllProducts(ownerId: user.uid);
      final rating = await _reviewsProvider.getUserRating(user.uid);
      if (!mounted) return;
      setState(() {
        _productCount = products.where((p) => p.moderationStatus != 'blocked').length;
        _rating = rating;
        _statsLoaded = true;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки статистики профиля: $e');
    }
  }

  Future<void> _loadRating(String userId) async {
    final rating = await _reviewsProvider.getUserRating(userId);
    if (!mounted) return;
    setState(() {
      _rating = rating;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return const SizedBox.shrink();

    final leasesProvider = context.watch<ActiveLeasesProvider>();
    final myLeases = leasesProvider.leases.where((l) => l.userId == user.uid).toList();
    final activeOrders = myLeases.where((l) => l.status == LeaseStatus.active).length;
    final incomingCount = context.watch<LeaseRequestProvider>()
        .getIncomingRequests(user.uid)
        .length;
    final completedCount = _archivedProvider.completedLeases.length;
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, incomingCount, theme),
              const SizedBox(height: 30),
              ProfileUserInfo(
                user: user,
                onTap: (user.role == 'admin' || user.role == 'support')
                    ? null
                    : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfile())),
              ),
              if (user.role == 'admin' || user.role == 'support') ...[
                const AdminDashboardWidget(),
              ],
              const SizedBox(height: 30),
              if (user.role == 'user') ...[
                _buildStats(activeOrders, completedCount, theme),
                const SizedBox(height: 15),
                ProfileAdsButton(
                  count: _productCount,
                  label: 'Мои объявления',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserOrders())),
                ),
                const SizedBox(height: 20),
                _buildActiveLeasesSection(context, myLeases, theme)
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(int activeOrders, int completedCount, ThemeData theme) {
    final ratingText = _statsLoaded ? _rating.toStringAsFixed(1) : '…';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn(
            value: '$activeOrders',
            label: 'Активных',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ActiveLeases()),
            ),
            theme: theme,
          ),
          _buildStatColumn(
            value: '$completedCount',
            label: 'Завершено',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArchivedLeasesScreen()),
            ),
            theme: theme,
          ),
          _buildStatColumn(
            value: ratingText,
            label: 'Рейтинг',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
            ),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String value,
    required String label,
    VoidCallback? onTap,
    required ThemeData theme,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: theme.colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int incomingCount, ThemeData theme) {
    final user = context.read<AuthProvider>().currentUser;
    return Row(
      children: [
        Text(
          'Профиль',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(width: 10),
        const Spacer(),
        if (user?.role == 'user')
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, size: 28, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
              if (incomingCount > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$incomingCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        GestureDetector(
          onTap: () => _showExitMenu(context),
          child: Icon(Icons.more_vert, size: 30, color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }

  void _showExitMenu(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuOption(
              icon: Icons.brightness_6,
              label: themeProvider.isDarkMode ? 'Светлая тема' : 'Тёмная тема',
              color: theme.colorScheme.onSurface,
              onTap: () {
                Navigator.pop(ctx);
                themeProvider.toggleTheme();
              },
              theme: theme,
            ),
            const SizedBox(height: 20),
            _buildMenuOption(
              icon: Icons.logout,
              label: 'Выйти',
              color: theme.colorScheme.onSurface,
              onTap: () {
                Navigator.pop(ctx);
                _logoutAndNavigate(context);
              },
              theme: theme,
            ),
            Divider(color: theme.dividerColor, height: 1, indent: 20, endIndent: 20),
            _buildMenuOption(
              icon: Icons.delete_forever_outlined,
              label: 'Удалить аккаунт',
              color: Colors.redAccent,
              isDestructive: true,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteAccount(context);
              },
              theme: theme,
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
    required ThemeData theme,
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
    await auth.logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
  void _confirmDeleteAccount(BuildContext context) {
    final userId = context.read<AuthProvider>().currentUser!.uid;
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        final navigatorCtx = Navigator.of(ctx);
        final navigatorContext = Navigator.of(context);
        final chatProvider = context.read<ChatProvider>();
        final leasesProvider = context.read<ActiveLeasesProvider>();
        final requestProvider = context.read<LeaseRequestProvider>();
        final basketProvider = context.read<BasketProvider>();
        final reviewsProvider = context.read<ReviewsProvider>();
        final favoriteProvider = context.read<FavoriteProvider>();
        final auth = context.read<AuthProvider>();
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 28),
              const SizedBox(width: 12),
              Text(
                'Удалить аккаунт?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
            ],
          ),
          content: Text(
            'Это действие необратимо. Все ваши данные будут удалены.',
            style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => navigatorCtx.pop(),
              child: Text('Отмена', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () async {
                navigatorCtx.pop();
                await ProductService.deleteProductsByOwner(userId);
                chatProvider.deleteChatsForUser(userId);
                leasesProvider.deleteLeasesForUser(userId);
                requestProvider.deleteRequestsForUser(userId);
                basketProvider.clearCartForUser(userId);
                reviewsProvider.deleteReviewsByUser(userId);
                favoriteProvider.clearFavoritesForUser(userId);
                await auth.deleteAccount();
                if (navigatorContext.context.mounted) {
                  navigatorContext.pushReplacementNamed('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Удалить', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveLeasesSection(BuildContext context, List leases, ThemeData theme) {
    final bool showAllButton = leases.length > 3;
    final List displayedLeases = showAllButton ? leases.take(3).toList() : leases;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Активные аренды',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: theme.colorScheme.onSurface),
            ),
            const Spacer(),
            if (showAllButton)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveLeases())),
                child: Text(
                  'Показать все',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ),
            if (showAllButton) ...[
              const SizedBox(width: 3),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: theme.colorScheme.onSurface),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (displayedLeases.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: Text(
              'Нет активных аренд',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
          )
        else
          ...displayedLeases.map((lease) => Padding(
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