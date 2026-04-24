import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ProductImage extends StatelessWidget {
  final List<String> images;
  final double width;
  final double height;
  final Color backgroundColor;
  final BoxFit fit;

  const ProductImage({
    required this.images,
    this.width = 100,
    this.height = 100,
    this.backgroundColor = AppColors.spaceCream,
    this.fit = BoxFit.cover,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return _buildPlaceholder();
    }

    final path = images[0];
    final isAsset = path.startsWith('assets/');

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: isAsset
          ? Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => _errorIcon(),
      )
          : Image.file(
        File(path),
        fit: fit,
        errorBuilder: (_, __, ___) => _errorIcon(),
      ),
    );
  }

  Widget _buildPlaceholder() => Container(
    width: width,
    height: height,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.oliveGray,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.image_not_supported, color: AppColors.spaceCream),
  );

  Widget _errorIcon() => Container(
    width: width,
    height: height,
    color: AppColors.oliveGray,
    child: const Icon(Icons.broken_image, color: AppColors.spaceCream),
  );
}