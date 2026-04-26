import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/pages/active_leases.dart';
import 'package:untitled/pages/edit_profile.dart';
import 'package:untitled/pages/user_orders.dart';
import 'package:untitled/pages/notifications.dart';
import 'package:untitled/provider/AuthProvider.dart';
import 'package:untitled/utils/colors.dart';
import '../../data/product_data.dart';
import '../../models/activeLease.dart';
import '../../provider/LeaseRequestProvider.dart';
import '../../provider/activeLeasesProvider.dart';
import '../lease_card.dart';
import '../../models/user.dart';

class ProfileOwn extends StatelessWidget {
  final UserModel user;

  const ProfileOwn({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final leasesProvider = context.watch<ActiveLeasesProvider>();
    final leases = leasesProvider.getLeasesForUser(user.id);
    final totalOrders = leases.length;
    final activeOrders = leases.where((l) => l.status == LeaseStatus.active).length;

    final incomingCount = context.watch<LeaseRequestProvider>()
        .getIncomingRequests(user.id)
        .length;

    final userProductsCount = ProductData.products
        .where((p) => p.ownerId == user.id)
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
              _buildUserInfo(context),
              const SizedBox(height: 30),
              _buildStats(totalOrders, activeOrders),
              const SizedBox(height: 15),
              _buildMyAdsButton(context, userProductsCount),
              const SizedBox(height: 20),
              _buildActiveLeasesSection(context, leases),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int incomingCount) {
    return Row(
      children: [
        const Text('Профиль',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
        const Spacer(),
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
          onTap: () async {
            final auth = context.read<AuthProvider>();
            await auth.logout();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
          child: const Icon(Icons.login_outlined, size: 30, color: AppColors.oliveGray),
        ),
      ],
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfile())),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: user.avatarPath != null
                ? Image.file(File(user.avatarPath!), height: 100, width: 100, fit: BoxFit.cover)
                : Image.asset('assets/silly_cat.jpg', height: 100, width: 100, fit: BoxFit.cover),
          ),
          const SizedBox(width: 30),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${user.firstName} ${user.lastName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
              const SizedBox(height: 2),
              Text(user.email, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(int totalOrders, int activeOrders) {
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

  Widget _buildMyAdsButton(BuildContext context, int count) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserOrders())),
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
            const Text('Мои объявления',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
            const Spacer(),
            _buildBadge(count),
            const SizedBox(width: 15),
            const Icon(Icons.arrow_circle_right_sharp, size: 14, color: AppColors.oliveGray),
          ],
        ),
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
            child: LeaseCard(lease: lease),
          )),
      ],
    );
  }

  Widget _buildBadge(int count) {
    return Container(
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
    );
  }
}