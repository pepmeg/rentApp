import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/review.dart';
import '../../../utils/colors.dart';

class ReviewCard extends StatefulWidget {
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
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final dateFormatted = DateFormat('dd.MM.yyyy').format(review.createdAt);
    final bool canModify = widget.onEdit != null || widget.onDelete != null;
    final bool isLong = review.text.length > 150;
    final displayText = (_expanded || !isLong)
        ? review.text
        : '${review.text.substring(0, 100)}...';

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
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.oliveGray.withOpacity(0.1),
                backgroundImage: review.userAvatarPath.isNotEmpty
                    ? (review.userAvatarPath.startsWith('assets/')
                    ? AssetImage(review.userAvatarPath)
                    : FileImage(File(review.userAvatarPath)))
                    : null,
                child: review.userAvatarPath.isEmpty
                    ? Icon(Icons.person, color: AppColors.oliveGray, size: 24)
                    : null,
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
                if (widget.onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: AppColors.oliveGray),
                    onPressed: widget.onEdit,
                    visualDensity: VisualDensity.compact,
                  ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: AppColors.wildWatermelon),
                    onPressed: widget.onDelete,
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
            Text(
              displayText,
              style: const TextStyle(fontSize: 14, color: AppColors.oliveGray),
            ),
            if (isLong) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  children: [
                    Text(
                      _expanded ? 'Свернуть' : 'Посмотреть полностью',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.copper,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppColors.copper,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}