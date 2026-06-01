import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin_models/report.dart';
import '../../provider/admin_provider.dart';
import '../../provider/AuthProvider.dart';
import '../../utils/snackbar_custom.dart';

void showReportDialog(BuildContext context, {
  required String reporterId,
  required ReportTargetType targetType,
  required String targetId,
  required String targetName,
}) {
  final authProvider = context.read<AuthProvider>();
  final currentUser = authProvider.currentUser;

  if (currentUser?.blocked == true) {
    SnackBarCustom.show(
      context,
      message: 'Ваш аккаунт заблокирован. Вы не можете отправлять жалобы.',
    );
    return;
  }

  final theme = Theme.of(context);
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
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              maxLength: 300,
              buildCounter: (context, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
              decoration: InputDecoration(
                hintText: 'Опишите нарушение...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                filled: true,
                fillColor: theme.colorScheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Отмена', style: TextStyle(color: theme.colorScheme.onSurface)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) return;
                    final admin = context.read<AdminProvider>();
                    admin.addReport(
                      reporterId: reporterId,
                      productId: isProduct ? targetId : null,
                      targetUserId: !isProduct ? targetId : null,
                      reason: reason,
                      targetType: targetType,
                    );
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