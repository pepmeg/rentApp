import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:untitled/utils/colors.dart';

class Product extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.arrow_left, size: 20, color: AppColors.copper,),
                Spacer(),
                Icon(Icons.heart_broken, size: 20, color: AppColors.wildWatermelon,),
              ],
            ),
            SizedBox(height: 20,),
            Image.asset(
              'asset/drill.png',
              height: 230,

            ),
            SizedBox(height: 20,),
            Row(
              children: [
                Text(
                  'Электродрель',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: AppColors.copper,),
                ),
                Spacer(),
                Text(
                  '500 ₽',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.copper,),
                ),
              ],
            ),
            SizedBox(height: 5,),
            Row(
              children: [
                Icon(Icons.star, size: 25, color: AppColors.macaroniCheese,),
                SizedBox(width: 3,),
                Text(
                  '4.8',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: AppColors.copper,),
                ),
                Spacer(),
                Text(
                  'за день',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w100, color: AppColors.copper,),
                ),
              ],
            ),
            SizedBox(height: 10,),
            Expanded(
                child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.copper,
                        foregroundColor: AppColors.oliveGray,
                        padding: const EdgeInsetsGeometry.symmetric(horizontal: 130, vertical: 5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)
                        )
                    ),
                    child: const Text(
                      'Купить',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                    )
                )
            ),
            SizedBox(height: 20,),
            Container(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: AppColors.macaroniCheese,
              ),
              child: Column(
                children: [
                  Text(
                    'Подробности',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.copper,),
                  ),
                  SizedBox(height: 2,),
                  Row(
                    children: [
                      Text(
                        'Категория:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w100, color: AppColors.copper,),
                      ),
                      SizedBox(height: 1,),
                      Text(
                        'Инструенты',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.copper,),
                      ),
                    ],
                  ),
                  SizedBox(height: 5,),
                  Text(
                    'Описание',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.copper,),
                  ),
                  SizedBox(height: 10,),
                  Text(
                    'Профессиональная электродрель с регулировкой скорости. Идеальна для домашнего ремонта и строительных работ.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.copper,),
                  ),
                  SizedBox(height: 20,),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'asset/drill.png',
                        height: 100,
                        width: 100,
                      ),
                      Spacer(),
                      Column(
                        children: [
                          Text(
                            'Никита Красильников',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.copper,),
                          ),
                          SizedBox(height: 5,),
                          Text(
                            '+79643435453',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.copper,),
                          ),
                          SizedBox(height: 5,),
                          Text(
                            'Республика Мордовия г. Чебупели ул. Сыктывка 18 кв. 15',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.copper,),
                          ),
                        ],
                      )
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