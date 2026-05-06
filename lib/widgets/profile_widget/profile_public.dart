import 'dart:io';
import 'package:AppRent/widgets/profile_widget/profile_common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pages/user_orders.dart';
import '../../data/product_data.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/admin_provider.dart';
import '../../provider/ReviewsProvider.dart';
import '../../provider/activeLeasesProvider.dart';
import '../../models/user.dart';
import '../../models/admin_models/report.dart';
import '../../utils/avatar.dart';
import '../../utils/colors.dart';
import '../../utils/snackbar_custom.dart';
import '../report_dialog.dart';

class ProfilePublic extends StatelessWidget {
  final UserModel user;

  const ProfilePublic({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final leasesProvider = context.watch<ActiveLeasesProvider>();
    final userLeases = leasesProvider.getLeasesForUser(user.id);
    final totalOrders = userLeases.length;

    final userProductsCount = ProductData.products
        .where((p) => p.ownerId == user.id && p.moderationStatus != 'blocked')
        .length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            ProfileUserInfo(user: user, showPhone: true),
            const SizedBox(height: 20),
            _buildStats(context, totalOrders, userProductsCount),
            const SizedBox(height: 20),
            ProfileAdsButton(
              count: userProductsCount,
              label: 'Объявления пользователя',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserOrders(ownerId: user.id)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final isOwnProfile = currentUser?.id == user.id;
    final canReport = !isOwnProfile && (currentUser?.role == 'user');
    return Row(
      children: [
        const Text('Профиль пользователя',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
        const Spacer(),
        if (canReport)
          IconButton(
            icon: Icon(Icons.flag_outlined, color: AppColors.oliveGray.withOpacity(0.7)),
            onPressed: () => showReportDialog(context,
              reporterId: currentUser!.id,
              targetType: ReportTargetType.user,
              targetId: user.id,
              targetName: '${user.firstName} ${user.lastName}',
            ),
          ),
      ],
    );
  }

  Widget _buildStats(BuildContext context, int totalOrders, int productsCount) {
    final reviewsProvider = context.watch<ReviewsProvider>();
    final userProducts = ProductData.products.where((p) => p.ownerId == user.id).toList();
    final userReviews = reviewsProvider.reviews.where((r) => userProducts.any((p) => p.id == r.productId)).toList();
    final double avgRating = userReviews.isEmpty
        ? 0.0
        : userReviews.map((r) => r.rating).reduce((a, b) => a + b) / userReviews.length;
    final String ratingText = userReviews.isEmpty ? '0' : avgRating.toStringAsFixed(1);

    return ProfileStatCard(columns: [
      ProfileStatColumn(value: '$totalOrders', label: 'Аренды'),
      ProfileStatColumn(value: '$productsCount', label: 'Объявления'),
      ProfileStatColumn(value: ratingText, label: 'Рейтинг'),
    ]);
  }
}