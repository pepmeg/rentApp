import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../services/storage_service.dart';

class ImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final VoidCallback? onDismiss;

  const ImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    this.onDismiss,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _closeViewer() {
    if (widget.onDismiss != null) widget.onDismiss!();
    Navigator.pop(context);
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }

    final file = File(path);
    if (file.existsSync()) {
      return FileImage(file);
    }

    final cachedUrl = StorageService.getCachedUrlSync(path);
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      return NetworkImage(cachedUrl);
    }

    return NetworkImage(cachedUrl ?? path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: _closeViewer,
        child: Stack(
          children: [
            Container(
              color: Colors.black.withOpacity(0.85),
            ),
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: _getImageProvider(widget.imageUrls[index]),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  heroAttributes: PhotoViewHeroAttributes(tag: widget.imageUrls[index]),
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 64, color: Colors.white38),
                          const SizedBox(height: 8),
                          Text('Не удалось загрузить', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    );
                  },
                );
              },
              itemCount: widget.imageUrls.length,
              loadingBuilder: (context, event) => Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    value: event == null ? null : event.expectedTotalBytes != null
                        ? event.cumulativeBytesLoaded / event.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              backgroundDecoration: const BoxDecoration(color: Colors.transparent),
              pageController: _pageController,
              onPageChanged: _onPageChanged,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _closeViewer,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 26),
                        ),
                      ),
                      const Spacer(),
                      if (widget.imageUrls.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${widget.imageUrls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}