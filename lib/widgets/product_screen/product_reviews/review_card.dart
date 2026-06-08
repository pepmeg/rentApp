import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/review.dart';
import '../../../theme/theme_data.dart';
import '../../../utils/avatar.dart';
import '../../../models/user.dart';

class ReviewCard extends StatefulWidget {
  final Review review;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReviewCard({required this.review, this.onEdit, this.onDelete, super.key});

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
    final displayText = (_expanded || !isLong) ? review.text : '${review.text.substring(0, 100)}...';
    final theme = Theme.of(context);

    final user = UserModel(
      uid: review.userId,
      email: '',
      firstName: review.userName.split(' ').first,
      lastName: review.userName.split(' ').length > 1 ? review.userName.split(' ').last : '',
      phoneNumber: '',
      address: '',
      avatarUrl: review.userAvatarPath,
      role: 'user',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              buildUserAvatar(context,user, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(dateFormatted, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              if (canModify) ...[
                if (widget.onEdit != null)
                  IconButton(
                    icon: Icon(Icons.edit, size: 18, color: theme.colorScheme.onSurface),
                    onPressed: widget.onEdit,
                    visualDensity: VisualDensity.compact,
                  ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete, size: 18, color: theme.colorScheme.error),
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
              color: AppTheme.starColor,
            )),
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(displayText, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface)),
            if (isLong) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  children: [
                    Text(_expanded ? 'Свернуть' : 'Посмотреть полностью', style: TextStyle(fontSize: 13, color: theme.primaryColor)),
                    const SizedBox(width: 4),
                    Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: theme.primaryColor),
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