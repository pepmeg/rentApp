import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../pages/user_orders.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/ReviewsProvider.dart';
import '../../services/product_service.dart';
import '../../provider/activeLeasesProvider.dart';
import '../../models/user.dart';
import '../../models/admin_models/report.dart';
import '../report_dialog.dart';
import 'profile_common.dart';

class ProfilePublic extends StatefulWidget {
  final UserModel user;
  const ProfilePublic({required this.user, super.key});

  @override
  State<ProfilePublic> createState() => _ProfilePublicState();
}

class _ProfilePublicState extends State<ProfilePublic> {
  late Future<_ProfileData> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _loadData();
  }

  Future<_ProfileData> _loadData() async {
    final user = widget.user;
    final reviewsProvider = context.read<ReviewsProvider>();
    final leasesProvider = context.read<ActiveLeasesProvider>();

    final productsFuture = ProductService.getAllProducts(ownerId: user.uid);
    final ratingFuture = reviewsProvider.getUserRating(user.uid);
    final ordersFuture = Future.value(leasesProvider.getLeasesForUser(user.uid).length);

    final results = await Future.wait([productsFuture, ratingFuture, ordersFuture]);
    final products = results[0] as List<Product>;
    final rating = results[1] as double;
    final orders = results[2] as int;

    return _ProfileData(
      productCount: products.where((p) => p.moderationStatus != 'blocked').length,
      rating: rating,
      totalOrders: orders,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final isTargetModerator = widget.user.role == 'admin' || widget.user.role == 'support';
    final bool showStatsAndAds = !widget.user.blocked && !isTargetModerator;
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, theme),
            const SizedBox(height: 20),
            ProfileUserInfo(user: widget.user, showPhone: true),
            const SizedBox(height: 20),
            if (widget.user.blocked) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.block_outlined, size: 24, color: theme.colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Пользователь заблокирован',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showStatsAndAds)
              FutureBuilder<_ProfileData>(
                future: _futureData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Ошибка загрузки'));
                  }
                  final data = snapshot.data!;
                  return Column(
                    children: [
                      _buildStats(theme, data),
                      const SizedBox(height: 20),
                      ProfileAdsButton(
                        count: data.productCount,
                        label: 'Объявления пользователя',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => UserOrders(ownerId: widget.user.uid)),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final isOwnProfile = currentUser?.uid == widget.user.uid;
    final canReport = !isOwnProfile && (currentUser?.role == 'user');
    return Row(
      children: [
        Text(
          'Профиль пользователя',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        const Spacer(),
        if (canReport)
          IconButton(
            icon: Icon(Icons.flag_outlined, color: theme.colorScheme.onSurface.withOpacity(0.7)),
            onPressed: () => showReportDialog(context,
              reporterId: currentUser!.uid,
              targetType: ReportTargetType.user,
              targetId: widget.user.uid,
              targetName: '${widget.user.firstName} ${widget.user.lastName}',
            ),
          ),
      ],
    );
  }

  Widget _buildStats(ThemeData theme, _ProfileData data) {
    final ratingText = data.rating.toStringAsFixed(1);
    return ProfileStatCard(columns: [
      ProfileStatColumn(value: '${data.totalOrders}', label: 'Аренды'),
      ProfileStatColumn(value: '${data.productCount}', label: 'Объявления'),
      ProfileStatColumn(value: ratingText, label: 'Рейтинг'),
    ]);
  }
}

class _ProfileData {
  final int productCount;
  final double rating;
  final int totalOrders;
  _ProfileData({required this.productCount, required this.rating, required this.totalOrders});
}