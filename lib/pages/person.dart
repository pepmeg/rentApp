import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/pages/active_leases.dart';
import 'package:untitled/pages/edit_profile.dart';
import 'package:untitled/pages/user_orders.dart';
import 'package:untitled/provider/AuthProvider.dart';
import 'package:untitled/utils/colors.dart';

import 'home.dart';

class Profile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Профиль',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
            ),
            SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfile(),
                  ),
                  );
                },
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        'assets/silly_cat.jpg',
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 30),
                    Column(
                      children: [
                        Text(
                          '${user?.firstName ?? ""} ${user?.lastName ?? ""}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${user?.email ?? ""}',
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
            SizedBox(height: 30,),
            Container(
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.whiteAntique,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: Column(
                    children: [
                      Text(
                        '12',
                        style: TextStyle(fontSize: 36,fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                      ),
                      SizedBox(height: 5,),
                      Text(
                        'Заказов',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                      ),
                    ],
                  ),
                  ),
                  Expanded(child: Column(
                    children: [
                      Text(
                        '3',
                        style: TextStyle(fontSize: 36,fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                      ),
                      SizedBox(height: 5,),
                      Text(
                        'Активных',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                      ),
                    ],
                  ),
                  ),
                  Expanded(child: Column(
                    children: [
                      Text(
                        '4.8',
                        style: TextStyle(fontSize: 36,fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                      ),
                      SizedBox(height: 5,),
                      Text(
                        'Рейтинг',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                      ),
                    ],
                  ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15,),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserOrders(),
                ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.whiteAntique,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_box, size: 22, color: AppColors.oliveGray,),
                    SizedBox(width: 15,),
                    Text(
                      'Мои заказы',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                    ),
                    const Spacer(),
                    Container(
                      width: 25,
                      height: 25,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.spaceCream,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        '3',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w100, color: AppColors.oliveGray),
                      ),
                    ),
                    SizedBox(width: 15,),
                    Icon(Icons.arrow_circle_right_sharp, size: 14, color: AppColors.oliveGray,)
                  ],
                ),
              ),
            ),
            SizedBox(height: 20,),
            Row(
              children: [
                Text(
                  'Активные аренды',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ActiveLeases(),
                    ),
                    );
                  },
                  child: Text(
                    'Показать все',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w100, color: AppColors.oliveGray),
                  ),
                ),
                SizedBox(width: 3,),
                Icon(Icons.arrow_circle_right_sharp, size: 10, color: AppColors.oliveGray,),
              ],
            ),
            SizedBox(height: 10,),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.whiteAntique,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Электродрель',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
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
