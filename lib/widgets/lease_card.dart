import 'package:flutter/material.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/models/activeLease.dart';
import 'package:untitled/widgets/plural.dart';

class LeaseCard extends StatelessWidget {
  final ActiveLease lease;

  const LeaseCard({required this.lease, super.key});

  @override
  Widget build(BuildContext context) {
    final bool isPending = lease.status == LeaseStatus.pending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.whiteAntique,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                lease.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: AppColors.oliveGray,
                ),
              ),
              const Spacer(),
              Container(
                height: 25,
                width: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isPending
                      ? AppColors.yellowSchoolBus
                      : AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  isPending ? 'Ожидание' : 'В аренде',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: AppColors.oliveGray,
                  ),
                ),
              ),
            ],
          ),
          if (!isPending) ...[
          const SizedBox(height: 15),
          Row(
            children: [
              Text(
                isPending
                    ? 'Дней: ${lease.totalDays}'
                    : 'Осталось: ${lease.remainingDays} ${Plural.days(lease.remainingDays)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: AppColors.oliveGray,
                ),
              ),
              const Spacer(),
              Text(
                '${lease.pricePerDay} ₽/день',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.oliveGray,
                ),
              ),
            ],
          ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        AppColors.wildWatermelon,
                        AppColors.macaroniCheese
                      ],
                    ).createShader(bounds),
                    child: LinearProgressIndicator(
                      value: lease.progress,
                      backgroundColor: AppColors.spaceCream,
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}