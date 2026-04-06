import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:untitled/utils/colors.dart';

class Profile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.all(20),
        child: Column(
          children: [
            Text(
              'Профиль',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            Expanded(
              child: Row(
                children: [
                  Image.asset(
                    'assets/silly_cat.jpg',
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(width: 30),
                  Column(
                    children: [
                      Text(
                        'Никита Красильников',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'nikita.krasilnikov@email.ru',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.macaroniCheese,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(
                        '12',
                        style: TextStyle(fontSize: 36,fontWeight: FontWeight.bold, color: AppColors.copper),
                      ),
                      SizedBox(height: 10,),
                      Text(
                        'Заказов',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.copper),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '3',
                        style: TextStyle(fontSize: 36,fontWeight: FontWeight.bold, color: AppColors.copper),
                      ),
                      SizedBox(height: 10,),
                      Text(
                        'Активных',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.copper),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '4.8',
                        style: TextStyle(fontSize: 36,fontWeight: FontWeight.bold, color: AppColors.copper),
                      ),
                      SizedBox(height: 10,),
                      Text(
                        'Рейтинг',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.copper),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 15,),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.macaroniCheese,
                borderRadius: BorderRadius.circular(30),
            ),
              child: Row(
                children: [
                  Icon(Icons.check_box, size: 22, color: AppColors.copper,),
                  SizedBox(width: 15,),
                  Text(
                    'Мои заказы',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.copper),
                  ),
                  const Spacer(),
                  Container(
                    width: 25,
                    height: 25,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '3',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w100, color: AppColors.copper),
                    ),
                  ),
                  SizedBox(width: 15,),
                  Icon(Icons.arrow_circle_right_sharp, size: 14, color: AppColors.copper,)
                ],
              ),
            ),
            SizedBox(height: 20,),
            Row(
              children: [
                Text(
                  'Активные аренды',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: AppColors.copper),
                ),
                Spacer(),
                Text(
                  'Показать все',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w100, color: AppColors.copper),
                ),
                SizedBox(width: 3,),
                Icon(Icons.arrow_circle_right_sharp, size: 10, color: AppColors.copper,),
              ],
            ),
            SizedBox(height: 10,),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.macaroniCheese,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Электродрель',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.copper),
                      ),
                      Spacer(),
                      Container(
                        height: 25,
                        width: 80,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          'В аренде',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15,),
                  Row(
                    children: [
                      Text(
                        'Осталось: 1 день',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                      ),
                      Spacer(),
                      Text(
                        '500 Руб.\день',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                      ),
                    ],
                  ),
                  SizedBox(height: 15,),
                  Row(
                    children: [
                      Expanded(
                          child:
                          ShaderMask(shaderCallback: (bounds) => LinearGradient(
                              colors: [AppColors.wildWatermelon, AppColors.macaroniCheese],
                          ).createShader(bounds),
                            child: LinearProgressIndicator(
                              value: 0.7,
                              backgroundColor: AppColors.spaceCream,
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              minHeight: 6,
                            ),
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
    );
  }
}
