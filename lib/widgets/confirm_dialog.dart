import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData icon;
  final Color? confirmColor;
  final bool isDestructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Удалить',
    this.cancelText = 'Отмена',
    this.icon = Icons.warning_amber_rounded,
    this.confirmColor,
    this.isDestructive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveConfirmColor = confirmColor ?? (isDestructive ? theme.colorScheme.error : theme.primaryColor);

    return Dialog(
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: effectiveConfirmColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: effectiveConfirmColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.25),
                    width: 1.5,
                  ),
                  minimumSize: const Size(0, 48),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    cancelText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: effectiveConfirmColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  minimumSize: const Size(0, 48),
                ),
                icon: isDestructive ? const Icon(Icons.delete_outline, size: 18) : null,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    confirmText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                  ),
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

Future<bool?> showConfirmDialog(
    BuildContext context, {
      required String title,
      required String message,
      String confirmText = 'Удалить',
      String cancelText = 'Отмена',
      IconData icon = Icons.warning_amber_rounded,
      Color? confirmColor,
      bool isDestructive = true,
    }) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => ConfirmDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
      confirmColor: confirmColor,
      isDestructive: isDestructive,
    ),
  );
}