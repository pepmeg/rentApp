import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/user.dart';
import '../../utils/colors.dart';

Widget buildUserAvatar(
    UserModel? user, {
      double radius = 20,
      String? fallbackImage,
      IconData fallbackIcon = Icons.person,
    }) {
  if (user?.role == 'admin') {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.oliveGray.withOpacity(0.2),
      child: Icon(Icons.admin_panel_settings, color: AppColors.oliveGray, size: radius * 1.2),
    );
  }
  if (user?.role == 'support') {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.lightGreen,
      child: Icon(Icons.headset_mic, color: Colors.white, size: radius * 1.2),
    );
  }
  if (user?.avatarPath != null && user!.avatarPath!.isNotEmpty) {
    if (user.avatarPath!.startsWith('assets/')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(user.avatarPath!),
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(user.avatarPath!)),
      );
    }
  }
  if (fallbackImage != null && fallbackImage.isNotEmpty) {
    if (fallbackImage.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(fallbackImage, width: radius * 2, height: radius * 2, fit: BoxFit.cover),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(fallbackImage), width: radius * 2, height: radius * 2, fit: BoxFit.cover),
      );
    }
  }
  return CircleAvatar(
    radius: radius,
    backgroundColor: AppColors.oliveGray.withOpacity(0.1),
    child: Icon(fallbackIcon, color: AppColors.oliveGray, size: radius),
  );
}