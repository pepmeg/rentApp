import 'package:flutter/material.dart';

class SnackBarCustom {
  static void show(
      BuildContext context, {
        required String message,
        String? actionLabel,
        VoidCallback? onAction,
      }) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          action: actionLabel != null && onAction != null
              ? SnackBarAction(
            label: actionLabel,
            textColor: theme.colorScheme.primary,
            onPressed: onAction,
          )
              : null,
          backgroundColor: theme.colorScheme.primaryContainer ?? theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
  }
}