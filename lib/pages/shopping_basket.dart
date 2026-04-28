import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/basket_card.dart';
import '../provider/basket_provider.dart';
import '../provider/AuthProvider.dart';
import '../utils/snackbar_custom.dart';

class ShoppingBasket extends StatefulWidget {
  const ShoppingBasket({super.key});

  @override
  State<ShoppingBasket> createState() => BasketState();
}

class BasketState extends State<ShoppingBasket> {
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      context.read<BasketProvider>().loadForUser(user.id);
    }
  }

  void _pay(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final basket = context.read<BasketProvider>();
    if (basket.getItemsForUser(user.id).isEmpty) return;
    basket.clearCartForUser(user.id);
    SnackBarCustom.show(context, message: 'Оплата прошла успешно!');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final basketProvider = context.watch<BasketProvider>();
    final cartItems = basketProvider.getItemsForUser(user.id);
    final totalPrice = basketProvider.totalPriceForUser(user.id);

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
              child: cartItems.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: AppColors.oliveGray.withOpacity(0.3),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Ваша корзина пуста',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.oliveGray.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Завершённые аренды появятся здесь',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.oliveGray.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
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
                    isHourly: item.isHourly,
                    extraHours: item.extraHours,
                  );
                },
              ),
            ),
            if (cartItems.isNotEmpty)
              Row(
                children: [
                  const Text(
                    'Итого',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                  ),
                  const Spacer(),
                  Text(
                    '$totalPrice ₽',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                  ),
                ],
              ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: cartItems.isNotEmpty
                  ? () => _pay(context)
                  : null,
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
                'Оплатить',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}