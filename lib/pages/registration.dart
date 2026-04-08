import 'package:flutter/material.dart';
import '../utils/colors.dart';

class Registration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 35, vertical: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Регистрация',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.normal, color: AppColors.copper),
            ),
            SizedBox(height: 50,),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.macaroniCheese,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    onChanged: (value) {},
                    decoration: InputDecoration(
                      hintText: 'Имя',
                      border: InputBorder.none,
                      contentPadding: EdgeInsetsGeometry.symmetric(vertical: 15, horizontal: 20),
                    ),
                  ),
                ),
                SizedBox(width: 10,),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.macaroniCheese,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    onChanged: (value) {},
                    decoration: InputDecoration(
                      hintText: 'Фамилия',
                      border: InputBorder.none,
                      contentPadding: EdgeInsetsGeometry.symmetric(vertical: 15, horizontal: 20),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10,),
            Container(
              decoration: BoxDecoration(
                color: AppColors.macaroniCheese,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                onChanged: (value) {},
                decoration: InputDecoration(
                  hintText: 'Адрес',
                  border: InputBorder.none,
                  contentPadding: EdgeInsetsGeometry.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
            ),
            SizedBox(height: 10,),
            Container(
              decoration: BoxDecoration(
                color: AppColors.macaroniCheese,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                onChanged: (value) {},
                decoration: InputDecoration(
                  hintText: 'yourmail@shrestha.com',
                  border: InputBorder.none,
                  contentPadding: EdgeInsetsGeometry.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
            ),
            SizedBox(height: 10,),
            Container(
              decoration: BoxDecoration(
                color: AppColors.macaroniCheese,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                onChanged: (value) {},
                decoration: InputDecoration(
                  hintText: 'Пароль',
                  border: InputBorder.none,
                  contentPadding: EdgeInsetsGeometry.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
            ),
            SizedBox(height: 10,),
            Container(
              decoration: BoxDecoration(
                color: AppColors.macaroniCheese,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                onChanged: (value) {},
                decoration: InputDecoration(
                  hintText: 'Подтвердите пароль',
                  border: InputBorder.none,
                  contentPadding: EdgeInsetsGeometry.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
            ),
            SizedBox(height: 30,),
            Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.macaroniCheese,
                      foregroundColor: AppColors.oliveGray,
                      padding: const EdgeInsetsGeometry.symmetric(horizontal: 60, vertical: 5)
                  ),
                  child: Text(
                    'Зарегестрироваться',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.normal, color: AppColors.copper),
                  ),
                )
            ),
            SizedBox(height: 30,),
            Text(
              'вернуться',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w100, color: AppColors.copper),
            ),
          ],
        ),
      ),
    );
  }
}