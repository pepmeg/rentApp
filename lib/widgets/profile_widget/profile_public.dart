import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/pages/user_orders.dart';
import 'package:untitled/utils/colors.dart';
import '../../data/product_data.dart';
import '../../provider/activeLeasesProvider.dart';
import '../../models/user.dart';

class ProfilePublic extends StatelessWidget {
  final UserModel user;

  const ProfilePublic({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final userProductsCount = ProductData.products
        .where((p) => p.ownerId == user.id)
        .length;
    final leasesProvider = context.read<ActiveLeasesProvider>();
    final totalOrders = leasesProvider.totalLeasesCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildUserInfo(),
          const SizedBox(height: 20),
          _buildStats(totalOrders, userProductsCount),
          const SizedBox(height: 20),
          _buildAdsButton(context, userProductsCount),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, size: 24, color: AppColors.oliveGray),
          onPressed: () => Navigator.pop(context),
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 5),
        const Text('Профиль пользователя',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: user.avatarPath != null
              ? Image.file(File(user.avatarPath!), width: 100, height: 100, fit: BoxFit.cover)
              : Image.asset('assets/silly_cat.jpg', width: 100, height: 100, fit: BoxFit.cover),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${user.firstName} ${user.lastName}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
              const SizedBox(height: 5),
              Text(user.email, style: const TextStyle(fontSize: 16, color: AppColors.oliveGray)),
              const SizedBox(height: 5),
              Text(user.phoneNumber, style: const TextStyle(fontSize: 16, color: AppColors.oliveGray)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats(int totalOrders, int productsCount) {
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
          _buildStatColumn('4.8', 'Рейтинг'),
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
            const Icon(Icons.check_box, size: 22, color: AppColors.oliveGray),
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
            const Icon(Icons.arrow_circle_right_sharp, size: 14, color: AppColors.oliveGray),
          ],
        ),
      ),
    );
  }
}