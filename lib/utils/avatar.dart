import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/storage_service.dart';
import '../theme/theme_data.dart';

final Map<String, Future<String?>> _avatarUrlFutures = {};

Widget buildUserAvatar(
    UserModel? user, {
      double radius = 20,
      String? fallbackImage,
      IconData fallbackIcon = Icons.person,
    }) {
  if (user?.role == 'admin') {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.withOpacity(0.2),
      child: Icon(Icons.admin_panel_settings, color: Colors.grey.shade700, size: radius * 1.2),
    );
  }
  if (user?.role == 'support') {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.lightGreen,
      child: Icon(Icons.headset_mic, color: Colors.white, size: radius * 1.2),
    );
  }

  final avatarUrl = user?.avatarUrl;

  return FutureBuilder<String?>(
    future: _resolveImageUrl(avatarUrl),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildLoadingAvatar(context, radius);
      }
      if (snapshot.hasError || snapshot.data == null) {
        return _buildFallbackAvatar(context, radius, fallbackImage, fallbackIcon);
      }

      final resolvedUrl = snapshot.data!;
      if (resolvedUrl.isNotEmpty) {
        return _buildNetworkAvatar(context, resolvedUrl, radius);
      }

      return _buildFallbackAvatar(context, radius, fallbackImage, fallbackIcon);
    },
  );
}

Widget _buildFallbackAvatar(BuildContext context, double radius, String? fallbackImage, IconData fallbackIcon) {
  final theme = Theme.of(context);
  if (fallbackImage != null && fallbackImage.isNotEmpty) {
    if (fallbackImage.startsWith('http://') || fallbackImage.startsWith('https://')) {
      return _buildNetworkAvatar(context, fallbackImage, radius);
    } else if (fallbackImage.startsWith('assets/')) {
      return ClipOval(
        child: Image.asset(fallbackImage, width: radius * 2, height: radius * 2, fit: BoxFit.cover),
      );
    } else {
      final file = File(fallbackImage);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(file, width: radius * 2, height: radius * 2, fit: BoxFit.cover),
        );
      }
    }
  }
  return CircleAvatar(
    radius: radius,
    backgroundColor: theme.colorScheme.onSurface.withOpacity(0.2),
    child: Icon(fallbackIcon, color: theme.colorScheme.onSurface, size: radius),
  );
}

Widget _buildLoadingAvatar(BuildContext context, double radius) {
  final theme = Theme.of(context);
  return CircleAvatar(
    radius: radius,
    backgroundColor: theme.colorScheme.onSurface.withOpacity(0.2),
    child: Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: theme.primaryColor,
      ),
    ),
  );
}

Widget _buildNetworkAvatar(BuildContext context, String url, double radius) {
  final theme = Theme.of(context);
  return ClipOval(
    child: CachedNetworkImage(
      imageUrl: url,
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildLoadingAvatar(context, radius),
      errorWidget: (context, url, error) => _buildFallbackAvatar(context, radius, null, Icons.person),
    ),
  );
}

Future<String?> _resolveImageUrl(String? pathOrUrl) {
  if (pathOrUrl == null || pathOrUrl.isEmpty) return Future.value(null);
  if (_avatarUrlFutures.containsKey(pathOrUrl)) {
    return _avatarUrlFutures[pathOrUrl]!;
  }
  final future = _fetchImageUrl(pathOrUrl);
  _avatarUrlFutures[pathOrUrl] = future;
  return future;
}

Future<String?> _fetchImageUrl(String pathOrUrl) async {
  // Если это уже полный HTTP/HTTPS URL – используем напрямую
  if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
    return pathOrUrl;
  }
  // Если это локальный файл или ассет – не трогаем (fallback)
  if (pathOrUrl.startsWith('assets/')) return null;
  final file = File(pathOrUrl);
  if (file.existsSync()) return null;
  // Иначе считаем, что это ключ Minio
  try {
    return await StorageService.getDownloadUrl(pathOrUrl).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Ошибка получения Presigned URL для аватара: $e');
    return null;
  }
}