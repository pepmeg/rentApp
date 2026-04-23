import 'dart:io';

import 'package:flutter/cupertino.dart';
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

class ProductScreen extends StatefulWidget {
  final Product product;

  const ProductScreen({required this.product, super.key});

  @override
  State<ProductScreen> createState() => ProductScreenState();
}

class ProductScreenState extends State<ProductScreen> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final isFavorite = favoriteProvider.isFavorite(widget.product.id);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final basketProvider = Provider.of<BasketProvider>(context);
    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.only(left: 20, right: 20, top: 40),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    size: 24,
                    color: AppColors.oliveGray,
                  ),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      favoriteProvider.toggleFavorite(widget.product.id);
                    });
                  },
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? AppColors.copper : AppColors.oliveGray,
                    size: 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            widget.product.images.isNotEmpty
                ? Image.asset(widget.product.images[0], height: 230)
                : Container(
                height: 230,
                color: AppColors.oliveGray,
                child: const Center(
                  child: Icon(Icons.image, size: 80, color: AppColors.oliveGray),
                ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                  widget.product.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: AppColors.oliveGray,
                  ),
                ),
                Spacer(),
                Text(
                  '${widget.product.price} ₽',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.oliveGray,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.star, size: 25, color: AppColors.yellowSchoolBus),
                SizedBox(width: 3),
                Text(
                  '4.8',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: AppColors.oliveGray,
                  ),
                ),
                Spacer(),
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
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final cartItem = CartItem(
                  id: widget.product.id,
                  name: widget.product.name,
                  price: widget.product.price,
                  images: widget.product.images,
                  days: 1,
                );
                basketProvider.addToCart(cartItem);
                final added = context.read<ActiveLeasesProvider>().addPendingLease(
                  ActiveLease(
                    productId: widget.product.id,
                    name: widget.product.name,
                    pricePerDay: widget.product.price,
                    totalDays: 1,
                    status: LeaseStatus.pending,
                  ),
                );
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                  SnackBar(
                    content: Text(added
                        ? 'Товар добавлен в корзину'
                        : 'Товар уже в аренде',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.whiteAntique),
                    ),
                    action: SnackBarAction(
                      label: 'В корзину',
                      textColor: AppColors.copper,
                      onPressed: () {
                        context.read<BottomNavProvider>().setIndex(3);
                        Navigator.pop(context);
                      },
                    ),
                    backgroundColor: AppColors.oliveGray,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.copper,
                foregroundColor: AppColors.spaceCream,
                padding: const EdgeInsetsGeometry.symmetric(vertical: 5),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Купить',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsetsGeometry.symmetric(
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
                  Text(
                    'Подробности',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.oliveGray,
                    ),
                  ),
                  SizedBox(height: 2),
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
                      SizedBox(height: 1),
                      Text(
                        'Инструенты',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: AppColors.oliveGray,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Описание',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.oliveGray,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Профессиональная электродрель с регулировкой скорости. Идеальна для домашнего ремонта и строительных работ.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: AppColors.oliveGray,
                    ),
                  ),
                  SizedBox(height: 20),
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
                      SizedBox(width: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user?.firstName} ${user?.lastName}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: AppColors.oliveGray,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '${user?.phoneNumber}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: AppColors.oliveGray,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '${user?.address}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: AppColors.oliveGray,
                            ),
                          ),
                        ],
                      ),
                    ],
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
