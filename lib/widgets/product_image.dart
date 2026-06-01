import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/storage_service.dart';

class ProductImage extends StatelessWidget {
  final List<String> images;
  final double width;
  final double height;
  final Color? backgroundColor;
  final BoxFit fit;
  final bool cacheUrls;

  const ProductImage({
    required this.images,
    this.width = 100,
    this.height = 100,
    this.backgroundColor,
    this.fit = BoxFit.cover,
    this.cacheUrls = false,
    super.key,
  });

  static final Map<String, Future<String?>> _urlFutures = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (images.isEmpty) {
      return _buildPlaceholder(theme);
    }

    final path = images[0];

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return _buildContainer(
        theme,
        child: CachedNetworkImage(
          imageUrl: path,
          fit: fit,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(strokeWidth: 3, color: theme.primaryColor),
          ),
          errorWidget: (context, url, error) => _errorIcon(theme),
        ),
      );
    }

    final file = File(path);
    if (file.existsSync()) {
      return _buildContainer(
        theme,
        child: Image.file(file, fit: fit, errorBuilder: (_, __, ___) => _errorIcon(theme)),
      );
    }

    return _buildContainer(
      theme,
      child: FutureBuilder<String?>(
        future: _resolveUrl(path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(strokeWidth: 3, color: theme.primaryColor),
            );
          }
          final url = snapshot.data;
          if (url == null || url.isEmpty) {
            return _errorIcon(theme);
          }
          return CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(strokeWidth: 3, color: theme.primaryColor),
            ),
            errorWidget: (context, url, error) => _errorIcon(theme),
          );
        },
      ),
    );
  }

  Future<String?> _resolveUrl(String objectKey) {
    if (_urlFutures.containsKey(objectKey)) {
      return _urlFutures[objectKey]!;
    }
    final future = _fetchUrl(objectKey);
    _urlFutures[objectKey] = future;
    return future;
  }

  Future<String?> _fetchUrl(String objectKey) async {
    final cached = await StorageService.getCachedUrl(objectKey);
    if (cached != null) return cached;
    try {
      return await StorageService.getDownloadUrl(objectKey, cache: cacheUrls)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Ошибка загрузки изображения $objectKey: $e');
      return null;
    }
  }

  Widget _buildContainer(ThemeData theme, {required Widget child}) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: child,
    );
  }

  Widget _buildPlaceholder(ThemeData theme) => Container(
    width: width,
    height: height,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: theme.colorScheme.onSurface.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.image_not_supported, color: theme.colorScheme.onSurface.withOpacity(0.5)),
  );

  Widget _errorIcon(ThemeData theme) => Container(
    width: width,
    height: height,
    color: theme.colorScheme.onSurface.withOpacity(0.3),
    child: Icon(Icons.broken_image, color: theme.colorScheme.onSurface.withOpacity(0.5)),
  );
}