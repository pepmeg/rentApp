import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/basket_card.dart';

import '../provider/basket_provider.dart';

class ShoppingBasket extends StatefulWidget {
  const ShoppingBasket({super.key});

  @override
  State<ShoppingBasket> createState() => BasketState();
}

  class BasketState extends State<ShoppingBasket> {
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
                fontWeight: FontWeight.w100,
                color: AppColors.oliveGray,
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
                    image: item.image,
                    days: item.days,
                    onDaysChanged: (newDays) {
                      basketProvider.updateDays(item.id, newDays);
                    },
                    onRemove: () {
                      basketProvider.removeFromCart(item.id);
                    },
                  );
                },
              ),
            ),
            //Spacer(),
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
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.copper,
                  foregroundColor: AppColors.spaceCream,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  'Оформить заказ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
