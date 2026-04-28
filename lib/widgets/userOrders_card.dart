import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/product_image.dart';
import 'package:untitled/models/activeLease.dart';
import '../provider/bottom_nav_provider.dart';

class UserOrdersCard extends StatelessWidget {
  final int id;
  final String name;
  final int price;
  final List<String> images;
  final String location;
  final DateTime createdAt;
  final ActiveLease? activeLease;
  final VoidCallback onEdit;
  final bool isOwner;

  const UserOrdersCard({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.location,
    required this.createdAt,
    this.activeLease,
    required this.onEdit,
    this.isOwner = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd.MM.yyyy').format(createdAt);
    return Card(
      color: AppColors.whiteAntique,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImage(
                  images: images,
                  width: 100,
                  height: 100,
                  backgroundColor: AppColors.whiteAntique,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: AppColors.oliveGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$price ₽ в день',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: AppColors.oliveGray,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.oliveGray,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.oliveGray.withOpacity(0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Дата выставления: $dateFormatted',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: AppColors.oliveGray.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  GestureDetector(
                    onTap: onEdit,
                    child: const Icon(
                      Icons.edit,
                      color: AppColors.oliveGray,
                      size: 20,
                    ),
                  ),
              ],
            ),
            if (activeLease != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  context.read<BottomNavProvider>().showUserProfile(
                    activeLease!.userId,
                  );
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.spaceCream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.oliveGray.withOpacity(0.1),
                        backgroundImage: activeLease!.userAvatarPath != null
                            ? FileImage(File(activeLease!.userAvatarPath!))
                            : null,
                        child: activeLease!.userAvatarPath == null
                            ? const Icon(
                                Icons.person,
                                size: 18,
                                color: AppColors.oliveGray,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Арендует: ${activeLease!.userFirstName} ${activeLease!.userLastName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.oliveGray,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.oliveGray,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
