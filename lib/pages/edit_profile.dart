import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/colors.dart';

class EditProfile extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 24, color: AppColors.oliveGray),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: 5,),
                Text(
                  'Редактировать',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                ),
              ],
            ),
            SizedBox(height: 15,),
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(
                'assets/silly_cat.jpg',
                height: 100,
                width: 100,
              ),
            ),
            SizedBox(height: 20,),
            TextField(
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Имя',
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  filled: true,
                  fillColor: AppColors.whiteAntique
              ),
            ),
            SizedBox(height: 10,),
            TextField(
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Фамилия',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.oliveGray, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  filled: true,
                  fillColor: AppColors.whiteAntique
              ),
            ),
            SizedBox(height: 10,),
            TextField(
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Адрес',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.oliveGray, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  filled: true,
                  fillColor: AppColors.whiteAntique
              ),
            ),
            SizedBox(height: 10,),
            TextField(
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Номер телефона',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.oliveGray, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  filled: true,
                  fillColor: AppColors.whiteAntique
              ),
            ),
            SizedBox(height: 10,),
            TextField(
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Почта',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.oliveGray, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                filled: true,
                fillColor: AppColors.whiteAntique
              ),
            ),
            SizedBox(height: 20,),
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
                'Сохранить',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}