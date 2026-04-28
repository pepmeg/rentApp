import 'dart:io';
import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class ProductImageGallery extends StatefulWidget {
  final List<String> images;
  const ProductImageGallery({required this.images, super.key});

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  int _currentImageIndex = 0;

  Widget _buildImage(int index) {
    final images = widget.images;
    if (images.isEmpty) {
      return Container(
        color: AppColors.oliveGray,
        child: const Center(
          child: Icon(Icons.image, size: 80, color: AppColors.spaceCream),
        ),
      );
    }

    final path = images[index];
    return (path.startsWith('assets/'))
        ? Image.asset(
      path,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.oliveGray,
        child: const Center(
          child: Icon(Icons.broken_image, size: 80, color: AppColors.spaceCream),
        ),
      ),
    )
        : Image.file(
      File(path),
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.oliveGray,
        child: const Center(
          child: Icon(Icons.broken_image, size: 80, color: AppColors.spaceCream),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
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
              color: isActive ? AppColors.copper : AppColors.oliveGray.withOpacity(0.4),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.images.isNotEmpty;

    return SizedBox(
      height: 280,
      child: Container(
        color: AppColors.oliveGray,
        child: hasImages
            ? Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemBuilder: (_, index) => _buildImage(index),
            ),
            if (widget.images.length > 1)
              Positioned(bottom: 8, child: _buildPageIndicator()),
          ],
        )
            : _buildImage(0),
      ),
    );
  }
}