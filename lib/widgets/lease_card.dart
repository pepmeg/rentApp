import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/models/activeLease.dart';
import 'package:untitled/pages/productScreen.dart';
import 'package:untitled/data/product_data.dart';
import '../models/lease_request.dart';
import '../provider/AuthProvider.dart';
import '../provider/LeaseRequestProvider.dart';
import '../provider/activeLeasesProvider.dart';
import '../utils/snackbar_custom.dart';

class LeaseCard extends StatelessWidget {
  final ActiveLease lease;

  const LeaseCard({required this.lease, super.key});

  @override
  Widget build(BuildContext context) {
    final bool isPending = lease.status == LeaseStatus.pending;
    final bool isActive = lease.status == LeaseStatus.active && !lease.isCompleted;

    return InkWell(
      onTap: () {
        final product = ProductData.getProductById(lease.productId);
        if (product != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
          );
        } else {
          SnackBarCustom.show(context, message: 'Товар не найден');
        }
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.whiteAntique,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lease.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.oliveGray),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 25,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isPending
                        ? AppColors.yellowSchoolBus
                        : isActive
                        ? AppColors.lightGreen
                        : AppColors.copper.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    isPending ? 'Ожидание' : (isActive ? 'В аренде' : 'На проверке'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.oliveGray),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  isPending
                      ? 'Дней: ${lease.totalDays}'
                      : 'Дней с начала: ${lease.currentDay}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                ),
                const Spacer(),
                Text(
                  '${lease.pricePerDay} ₽/день',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                ),
              ],
            ),
            if (lease.isPendingCompletion) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.copper.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Ожидание подтверждения',
                  style: TextStyle(
                    color: AppColors.copper,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (isActive) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.copper,
                    foregroundColor: AppColors.whiteAntique,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('Завершить аренду', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  onPressed: () {
                    final leasesProvider = context.read<ActiveLeasesProvider>();
                    final leaseRequestProvider = context.read<LeaseRequestProvider>();
                    final user = context.read<AuthProvider>().currentUser;
                    if (user == null) return;
                    leasesProvider.requestCompleteLease(lease.productId);
                    leaseRequestProvider.addRequest(LeaseRequest(
                      id: DateTime.now().millisecondsSinceEpoch,
                      productId: lease.productId,
                      productName: lease.name,
                      pricePerDay: lease.pricePerDay,
                      totalDays: lease.totalDays,
                      requesterId: user.id,
                      requesterFirstName: user.firstName,
                      requesterLastName: user.lastName,
                      requesterAvatarPath: user.avatarPath,
                      ownerId: lease.ownerId,
                      type: RequestType.completion,
                    ));
                    SnackBarCustom.show(context, message: 'Запрос на завершение отправлен владельцу');
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}