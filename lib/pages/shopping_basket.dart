import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/basket_card.dart';

import '../main.dart';
import '../models/activeLease.dart';
import '../provider/activeLeasesProvider.dart';
import '../provider/basket_provider.dart';
import '../provider/bottom_nav_provider.dart';

class ShoppingBasket extends StatefulWidget {
  const ShoppingBasket({super.key});

  @override
  State<ShoppingBasket> createState() => BasketState();
}

  class BasketState extends State<ShoppingBasket> {

    void checkout(BuildContext context) {
      final basket = Provider.of<BasketProvider>(context, listen: false);
      final leasesProvider = Provider.of<ActiveLeasesProvider>(context, listen: false);

      for (var item in basket.items) {
        leasesProvider.activateLease(
          item.id,
          item.name,
          item.price,
          item.days,
        );
      }

      basket.clearCart();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
        SnackBar(content: const Text(
          'Уже в аренде',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.whiteAntique),
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
      context.read<BottomNavProvider>().setIndex(4);
    }

  @override
  Widget build(BuildContext context) {
    final basketProvider = Provider.of<BasketProvider>(context);
    final cartItems = basketProvider.items;
    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Корзина',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.oliveGray,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '${cartItems.length} товара',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: AppColors.oliveGray.withOpacity(0.5),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 20),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return BasketCard(
                    id: item.id,
                    name: item.name,
                    price: item.price,
                    images: item.images,
                    days: item.days,
                    onDaysChanged: (newDays) {
                      basketProvider.updateDays(item.id, newDays);
                    },
                    onRemove: () {
                      basketProvider.removeFromCart(item.id);
                      context.read<ActiveLeasesProvider>().removePendingLeaseByProductId(item.id);
                    },
                  );
                },
              ),
            ),
            if (basketProvider.items.isNotEmpty)
            Row(
              children: [
                Text(
                  'Итого',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                ),
                const Spacer(),
                Text(
                  '${basketProvider.totalPrice} ₽',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                ),
              ],
            ),
            SizedBox(height: 15,),
            ElevatedButton(
              onPressed: basketProvider.items.isEmpty
                  ? null
                  : () {
                  checkout(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.copper,
                  disabledBackgroundColor: AppColors.oliveGray.withOpacity(0.3),
                  foregroundColor: AppColors.spaceCream,
                  disabledForegroundColor: AppColors.whiteAntique.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  'Оформить аренду',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
