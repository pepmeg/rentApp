import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/basket_card.dart';
import '../models/activeLease.dart';
import '../provider/activeLeasesProvider.dart';
import '../provider/basket_provider.dart';
import '../utils/snackbar_custom.dart';

class ShoppingBasket extends StatefulWidget {
  const ShoppingBasket({super.key});

  @override
  State<ShoppingBasket> createState() => BasketState();
}

class BasketState extends State<ShoppingBasket> {

  void checkout(BuildContext context) {
    final basket = Provider.of<BasketProvider>(context, listen: false);
    basket.clearCart();
    SnackBarCustom.show(context, message: 'Корзина очищена (оплата будет позже)');
  }

  @override
  Widget build(BuildContext context) {
    final basketProvider = Provider.of<BasketProvider>(context);
    final cartItems = basketProvider.items;

    final activeLeases = context.watch<ActiveLeasesProvider>().leases;
    final hasInvalidDays = cartItems.any((item) => item.days <= 0);
    final hasActiveLeaseConflict = cartItems.any((item) {
      return activeLeases.any((lease) =>
      lease.productId == item.id && lease.status == LeaseStatus.active);
    });
    final canCheckout = cartItems.isNotEmpty && !hasInvalidDays && !hasActiveLeaseConflict;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Корзина',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.oliveGray,
              ),
            ),
            const SizedBox(height: 2),
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
                padding: const EdgeInsets.symmetric(vertical: 20),
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
                  const Text(
                    'Итого',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                  ),
                  const Spacer(),
                  Text(
                    '${basketProvider.totalPrice} ₽',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                  ),
                ],
              ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: canCheckout ? () => checkout(context) : null,
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