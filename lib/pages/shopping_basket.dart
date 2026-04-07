import 'package:flutter/material.dart';
import 'package:untitled/utils/colors.dart';

class ShoppingBasket extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.all(20),
        child: Column(
          children: [
            Text(
              'Корзина',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.copper,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '2 товара',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w100,
                color: AppColors.copper,
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsetsGeometry.all(25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: AppColors.macaroniCheese,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/silly_cat.jpg',
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(width: 15),
                      Column(
                        children: [
                          Text(
                            'Электродрель',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
                              color: AppColors.copper,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(width: 5),
                          Text(
                            '500 ₽ за день',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w100,
                              color: AppColors.copper,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.shopping_basket,
                        size: 30,
                        color: AppColors.copper,
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: AppColors.oliveGray,
                    ),
                    child: Row(
                        children: [
                          Text(
                              'Срок аренды',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.copper),
                          ),
                          Spacer(),
                          Icon(Icons.plus_one, size: 15, color: AppColors.copper,),
                          SizedBox(width: 15,),
                          Text(
                            '2 дня',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.copper),
                          ),
                          SizedBox(width: 15,),
                          Icon(Icons.exposure_minus_1, size: 15, color: AppColors.copper,),
                        ]
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            Row(
              children: [
                Text(
                  'Итого',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.copper),
                ),
                Spacer(),
                Text(
                  '1700 ₽',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.copper),
                ),
              ],
            ),
            Expanded(
                child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.copper,
                      foregroundColor: AppColors.oliveGray,
                      padding: const EdgeInsetsGeometry.symmetric(horizontal: 75, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)
                      )
                    ),
                    child: const Text(
                      'Оформить заказ',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                    )
                )
            ),
          ],
        ),
      ),
    );
  }
}
