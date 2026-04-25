import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/models/product.dart';
import 'package:untitled/provider/basket_provider.dart';
import 'package:untitled/utils/colors.dart';
import '../models/activeLease.dart';
import '../models/cart_item.dart';
import '../provider/AuthProvider.dart';
import '../provider/activeLeasesProvider.dart';
import '../provider/bottom_nav_provider.dart';
import '../provider/favorite_provider.dart';
import '../utils/snackbar_custom.dart';
import '../widgets/lease_card.dart';
import '../widgets/plural.dart';

class ProductScreen extends StatefulWidget {
  final Product product;

  const ProductScreen({required this.product, super.key});

  @override
  State<ProductScreen> createState() => ProductScreenState();
}

class ProductScreenState extends State<ProductScreen> {
  int _currentImageIndex = 0;

  Widget _buildImage(int index) {
    final images = widget.product.images;
    if (images.isEmpty) {
      return Container(
        color: AppColors.oliveGray,
        child: const Center(
          child: Icon(Icons.image, size: 80, color: AppColors.spaceCream),
        ),
      );
    }

    final path = images[index];
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.oliveGray,
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 80,
              color: AppColors.spaceCream,
            ),
          ),
        ),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.oliveGray,
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 80,
              color: AppColors.spaceCream,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildPageIndicator() {
    final count = widget.product.images.length;
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
              color: isActive
                  ? AppColors.copper
                  : AppColors.oliveGray.withOpacity(0.4),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final isFavorite = favoriteProvider.isFavorite(widget.product.id);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final basketProvider = Provider.of<BasketProvider>(context);
    final hasImages = widget.product.images.isNotEmpty;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: AppColors.oliveGray,
                    ),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        favoriteProvider.toggleFavorite(widget.product.id);
                      });
                    },
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? AppColors.copper
                          : AppColors.oliveGray,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 280,
              child: Container(
                color: AppColors.oliveGray,
                child: hasImages
                    ? Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          PageView.builder(
                            itemCount: widget.product.images.length,
                            onPageChanged: (index) {
                              setState(() => _currentImageIndex = index);
                            },
                            itemBuilder: (context, index) {
                              final path = widget.product.images[index];
                              return path.startsWith('assets/')
                                  ? Image.asset(
                                      path,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.oliveGray,
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 80,
                                            color: AppColors.spaceCream,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Image.file(
                                      File(path),
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.oliveGray,
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 80,
                                            color: AppColors.spaceCream,
                                          ),
                                        ),
                                      ),
                                    );
                            },
                          ),
                          if (widget.product.images.length > 1)
                            Positioned(bottom: 8, child: _buildPageIndicator()),
                        ],
                      )
                    : _buildImage(0),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                            color: AppColors.oliveGray,
                          ),
                        ),
                      ),
                      Text(
                        '${widget.product.price} ₽',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.oliveGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 25,
                        color: AppColors.yellowSchoolBus,
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        '4.8',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          color: AppColors.oliveGray,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'за день',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: AppColors.oliveGray.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      final added = context.read<ActiveLeasesProvider>().addPendingLease(
                        ActiveLease(
                          productId: widget.product.id,
                          name: widget.product.name,
                          pricePerDay: widget.product.price,
                          totalDays: 1,
                          status: LeaseStatus.pending,
                        ),
                      );
                      if (added) {
                        final cartItem = CartItem(
                          id: widget.product.id,
                          name: widget.product.name,
                          price: widget.product.price,
                          images: widget.product.images,
                          ownerId: widget.product.ownerId,
                          days: 1,
                        );
                        basketProvider.addToCart(cartItem);
                      }
                      SnackBarCustom.show(
                        context,
                        message: added ? 'Товар добавлен в корзину' : 'Товар уже в аренде',
                        actionLabel: added ? 'В корзину' : null,
                        onAction: added
                            ? () {
                          context.read<BottomNavProvider>().setIndex(3);
                          Navigator.pop(context);
                        }
                            : null,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.copper,
                      foregroundColor: AppColors.spaceCream,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Арендовать',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: AppColors.spaceCream,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Подробности',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.oliveGray,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Категория:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: AppColors.oliveGray.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.product.category.isNotEmpty
                                  ? widget.product.category
                                  : 'Не указана',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: AppColors.oliveGray,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              'Подкатегория:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: AppColors.oliveGray.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.product.subcategory.isNotEmpty
                                  ? widget.product.subcategory
                                  : 'Не указана',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: AppColors.oliveGray,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              'Бренд:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: AppColors.oliveGray.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.product.brand.isNotEmpty
                                  ? widget.product.brand
                                  : 'Не указан',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: AppColors.oliveGray,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              'Минимальный срок аренды:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: AppColors.oliveGray.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.product.minRentDays} ${Plural.days(widget.product.minRentDays)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: AppColors.oliveGray,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Описание',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.oliveGray,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.product.description.isNotEmpty
                              ? widget.product.description
                              : 'Нет описания',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: AppColors.oliveGray,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: user?.avatarPath != null
                                  ? Image.file(
                                      File(user!.avatarPath!),
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/silly_cat.jpg',
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(width: 30),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${user?.firstName} ${user?.lastName}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                      color: AppColors.oliveGray,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${user?.phoneNumber}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                      color: AppColors.oliveGray,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${user?.address}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                      color: AppColors.oliveGray,
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
