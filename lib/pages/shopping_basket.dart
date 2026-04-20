import 'package:flutter/material.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/basket_card.dart';

class ShoppingBasket extends StatefulWidget {
  const ShoppingBasket({super.key});

  @override
  State<ShoppingBasket> createState() => BasketState();
}

class CartItem {
  final String name;
  final String image;
  final int price;
  final int days;

  const CartItem({
    required this.name,
    required this.image,
    required this.price,
    required this.days,
  });
}

  class BasketState extends State<ShoppingBasket> {
  @override
  Widget build(BuildContext context) {
    final List<CartItem> cartItems = const [
      CartItem(name: 'Электродрель', image: 'assets/silly_cat.jpg', price: 500, days: 2),
    ];
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
              '2 товара',
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
                    name: item.name,
                    price: item.price,
                    image: item.image,
                    days: item.days,
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
                  '1700 ₽',
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
