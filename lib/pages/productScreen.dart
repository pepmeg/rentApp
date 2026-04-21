import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/models/product.dart';
import 'package:untitled/utils/colors.dart';
import '../provider/AuthProvider.dart';

class ProductScreen extends StatelessWidget{
  final Product product;
  const ProductScreen({required this.product, super.key});

  @override
  Widget build(BuildContext context){
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.only(left: 20, right: 20, top: 40),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 24, color: AppColors.oliveGray),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                ),
                Spacer(),
                Icon(Icons.heart_broken, size: 20, color: AppColors.wildWatermelon,),
              ],
            ),
            SizedBox(height: 20,),
            Image.asset(
              product.image,
              height: 230,
            ),
            SizedBox(height: 20,),
            Row(
              children: [
                Text(
                  product.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: AppColors.oliveGray,),
                ),
                Spacer(),
                Text(
                  '${product.price} ₽',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oliveGray,),
                ),
              ],
            ),
            SizedBox(height: 5,),
            Row(
              children: [
                Icon(Icons.star, size: 25, color: AppColors.yellowSchoolBus,),
                SizedBox(width: 3,),
                Text(
                  '4.8',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: AppColors.oliveGray,),
                ),
                Spacer(),
                Text(
                  'за день',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w100, color: AppColors.oliveGray,),
                ),
              ],
            ),
            SizedBox(height: 10,),
        ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.copper,
                        foregroundColor: AppColors.spaceCream,
                        padding: const EdgeInsetsGeometry.symmetric(vertical: 5),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)
                        )
                    ),
                    child: const Text(
                      'Купить',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    )
                ),
            SizedBox(height: 20,),
            Container(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: AppColors.spaceCream,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Подробности',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray,),
                  ),
                  SizedBox(height: 2,),
                  Row(
                    children: [
                      Text(
                        'Категория:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w100, color: AppColors.oliveGray,),
                      ),
                      SizedBox(height: 1,),
                      Text(
                        'Инструенты',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray,),
                      ),
                    ],
                  ),
                  SizedBox(height: 5,),
                  Text(
                    'Описание',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray,),
                  ),
                  SizedBox(height: 10,),
                  Text(
                    'Профессиональная электродрель с регулировкой скорости. Идеальна для домашнего ремонта и строительных работ.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray,),
                  ),
                  SizedBox(height: 20,),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(
                          'assets/silly_cat.jpg',
                          height: 100,
                          width: 100,
                        ),
                      ),
                      SizedBox(width: 30,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user?.firstName} ${user?.lastName}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray,),
                          ),
                          SizedBox(height: 5,),
                          Text(
                            '${user?.phoneNumber}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray,),
                          ),
                          SizedBox(height: 5,),
                          Text(
                            '${user?.address}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray,),
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