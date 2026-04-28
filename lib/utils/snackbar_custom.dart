import 'package:flutter/material.dart';
import '../utils/colors.dart';

class SnackBarCustom {
  static void show(
      BuildContext context, {
        required String message,
        String? actionLabel,
        VoidCallback? onAction,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: AppColors.whiteAntique,
            ),
          ),
          action: actionLabel != null
              ? SnackBarAction(
            label: actionLabel,
            textColor: AppColors.copper,
            onPressed: onAction ?? () {},
          )
              : null,
          backgroundColor: AppColors.oliveGray,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}