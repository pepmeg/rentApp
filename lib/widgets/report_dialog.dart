import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin_models/report.dart';
import '../../provider/admin_provider.dart';
import '../../utils/colors.dart';
import '../../utils/snackbar_custom.dart';

void showReportDialog(BuildContext context, {
  required int reporterId,
  required ReportTargetType targetType,
  required int targetId,
  required String targetName,
}) {
  final reasonController = TextEditingController();
  final isProduct = targetType == ReportTargetType.product;
  final title = isProduct ? 'Пожаловаться на товар' : 'Пожаловаться на пользователя';
  final description = isProduct
      ? 'Укажите причину жалобы на "$targetName"'
      : 'Укажите причину жалобы на $targetName';

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.whiteAntique,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.oliveGray),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(color: AppColors.oliveGray.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              maxLength: 300,
              buildCounter: (context, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
              decoration: InputDecoration(
                hintText: 'Опишите нарушение...',
                hintStyle: TextStyle(color: AppColors.oliveGray.withOpacity(0.5)),
                filled: true,
                fillColor: AppColors.spaceCream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена', style: TextStyle(color: AppColors.oliveGray)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.copper,
                    foregroundColor: AppColors.whiteAntique,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) return;
                    final admin = context.read<AdminProvider>();
                    if (targetType == ReportTargetType.product) {
                      admin.addReport(
                        reporterId: reporterId,
                        productId: targetId,
                        reason: reason,
                        targetType: ReportTargetType.product,
                      );
                    } else {
                      admin.addReport(
                        reporterId: reporterId,
                        targetUserId: targetId,
                        reason: reason,
                        targetType: ReportTargetType.user,
                      );
                    }
                    SnackBarCustom.show(context, message: 'Жалоба отправлена');
                    Navigator.pop(ctx);
                  },
                  child: const Text('Отправить'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}