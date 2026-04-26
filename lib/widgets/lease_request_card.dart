import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/provider/LeaseRequestProvider.dart';
import 'package:untitled/provider/activeLeasesProvider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/product_image.dart';
import '../models/lease_request.dart';

class LeaseRequestCard extends StatelessWidget {
  final LeaseRequest request;
  final VoidCallback? onUserTap;

  const LeaseRequestCard({
    required this.request,
    this.onUserTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: AppColors.oliveGray.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.whiteAntique,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ProductImage(
                    images: request.images,
                    width: 80,
                    height: 80,
                    backgroundColor: AppColors.spaceCream,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.productName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.oliveGray,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${request.pricePerDay} ₽ / день',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.oliveGray.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: AppColors.oliveGray.withOpacity(0.1),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onUserTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: request.requesterAvatarPath != null
                          ? Image.file(
                        File(request.requesterAvatarPath!),
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      )
                          : Image.asset(
                        'assets/silly_cat.jpg',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${request.requesterFirstName} ${request.requesterLastName} хочет арендовать',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.oliveGray.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.oliveGray.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<LeaseRequestProvider>().acceptRequest(
                        request.id,
                        context.read<ActiveLeasesProvider>(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.copper,
                      foregroundColor: AppColors.whiteAntique,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Принять',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<LeaseRequestProvider>().rejectRequest(request.id);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.oliveGray,
                      side: BorderSide(color: AppColors.oliveGray.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Отклонить',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}