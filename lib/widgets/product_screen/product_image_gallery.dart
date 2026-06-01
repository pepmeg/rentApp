import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/storage_service.dart';

class ProductImageGallery extends StatefulWidget {
  final List<String> images;
  final bool cacheUrls;
  const ProductImageGallery({required this.images, this.cacheUrls = false, super.key});
  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}
class _ProductImageGalleryState extends State<ProductImageGallery> {
  int _currentImageIndex = 0;
  static final Map<String, Future<String?>> _urlFutures = {};
  Widget _buildImage(int index, ThemeData theme) {
    final images = widget.images;
    if (images.isEmpty) {
      return Container(
        color: theme.colorScheme.onSurface.withOpacity(0.3),
        child: const Center(
          child: Icon(Icons.image, size: 80),
        ),
      );
    }
    final path = images[index];
    return _buildImageWidget(path, theme);
  }
  Widget _buildImageWidget(String path, ThemeData theme) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return _buildNetworkImage(path, theme);
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _buildLoadingPlaceholder(theme),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _buildLoadingPlaceholder(theme),
      );
    }
    return FutureBuilder<String?>(
      future: _resolveUrl(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPlaceholder(theme);
        }
        final url = snapshot.data;
        if (url == null || url.isEmpty) {
          return _buildLoadingPlaceholder(theme);
        }
        return _buildNetworkImage(url, theme);
      },
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
      return await StorageService.getDownloadUrl(objectKey, cache: widget.cacheUrls)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Ошибка загрузки изображения галереи $objectKey: $e');
      return null;
    }
  }

  Widget _buildNetworkImage(String url, ThemeData theme) {
    return Container(
      color: theme.colorScheme.onSurface.withOpacity(0.3),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        width: double.infinity,
        placeholder: (context, url) => _buildLoadingPlaceholder(theme),
        errorWidget: (context, url, error) => _buildLoadingPlaceholder(theme),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.onSurface.withOpacity(0.1),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }

  Widget _buildPageIndicator(ThemeData theme) {
    final count = widget.images.length;
    if (count <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = index == _currentImageIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive ? theme.primaryColor : theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImages = widget.images.isNotEmpty;
    return SizedBox(
      height: 280,
      child: Container(
        color: theme.colorScheme.onSurface.withOpacity(0.3),
        child: hasImages
            ? Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemBuilder: (_, index) => _buildImage(index, theme),
            ),
            if (widget.images.length > 1)
              Positioned(bottom: 8, child: _buildPageIndicator(theme)),
          ],
        )
            : _buildImage(0, theme),
      ),
    );
  }
}