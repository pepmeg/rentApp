import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pages/user_orders.dart';
import '../../data/product_data.dart';
import '../../provider/ReviewsProvider.dart';
import '../../provider/activeLeasesProvider.dart';
import '../../models/user.dart';
import '../../utils/colors.dart';

class ProfilePublic extends StatelessWidget {
  final UserModel user;

  const ProfilePublic({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final leasesProvider = context.watch<ActiveLeasesProvider>();
    final userLeases = leasesProvider.getLeasesForUser(user.id);
    final totalOrders = userLeases.length;

    final userProductsCount = ProductData.products
        .where((p) => p.ownerId == user.id)
        .length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildUserInfo(),
            const SizedBox(height: 20),
            _buildStats(context, totalOrders, userProductsCount),
            const SizedBox(height: 20),
            _buildAdsButton(context, userProductsCount),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Text('Профиль пользователя',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.oliveGray.withOpacity(0.1),
          backgroundImage: user.avatarPath != null
              ? (user.avatarPath!.startsWith('assets/')
              ? AssetImage(user.avatarPath!)
              : FileImage(File(user.avatarPath!)))
              : null,
          child: user.avatarPath == null
              ? Icon(Icons.person, color: AppColors.oliveGray, size: 50)
              : null,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${user.firstName} ${user.lastName}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Text(user.email, style: const TextStyle(fontSize: 16, color: AppColors.oliveGray), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Text(user.phoneNumber, style: const TextStyle(fontSize: 16, color: AppColors.oliveGray), overflow: TextOverflow.ellipsis),
            ],
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
          _buildStatColumn('$productsCount', 'Объявления'),
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

  Widget _buildAdsButton(BuildContext context, int count) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserOrders(ownerId: user.id)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.whiteAntique,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const Icon(Icons.list_alt_rounded, size: 22, color: AppColors.oliveGray),
            const SizedBox(width: 15),
            const Text('Объявления пользователя',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
            const Spacer(),
            Container(
              constraints: const BoxConstraints(minWidth: 25),
              height: 25,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.spaceCream,
                borderRadius: BorderRadius.circular(12.5),
              ),
              child: Text('$count',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.oliveGray.withOpacity(0.5))),
            ),
            const SizedBox(width: 15),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.oliveGray),
          ],
        ),
      ),
    );
  }
}