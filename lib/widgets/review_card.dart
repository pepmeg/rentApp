import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled/models/review.dart';
import 'package:untitled/utils/colors.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReviewCard({
    required this.review,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd.MM.yyyy').format(review.createdAt);
    final bool canModify = onEdit != null || onDelete != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteAntique,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: review.userAvatarPath.isNotEmpty
                    ? Image.file(File(review.userAvatarPath), width: 40, height: 40, fit: BoxFit.cover)
                    : Image.asset('assets/silly_cat.jpg', width: 40, height: 40, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.oliveGray)),
                    const SizedBox(height: 2),
                    Text(dateFormatted, style: TextStyle(fontSize: 12, color: AppColors.oliveGray.withOpacity(0.5))),
                  ],
                ),
              ),
              if (canModify) ...[
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: AppColors.oliveGray),
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: AppColors.wildWatermelon),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) => Icon(
              i < review.rating ? Icons.star : Icons.star_border,
              size: 18,
              color: AppColors.yellowSchoolBus,
            )),
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.text, style: const TextStyle(fontSize: 14, color: AppColors.oliveGray)),
          ],
        ],
      ),
    );
  }
}