import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:untitled/utils/colors.dart';

class Add_Product extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_right, size: 24, color: AppColors.copper,),
                SizedBox(width: 20,),
                Text(
                  'Добавить товар',
                  style: TextStyle(fontSize: 24,fontWeight: FontWeight.normal, color: AppColors.copper),
                ),
              ],
            ),
            SizedBox(height: 10,),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (context, index){
                    return GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.macaroniCheese,
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    );
                  }
              ),
            ),
            SizedBox(height: 10,),
            TextField(
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Название товара',
                border: InputBorder.none,
                contentPadding: EdgeInsetsGeometry.symmetric(vertical: 20, horizontal: 10),
              ),
            ),
            SizedBox(height: 10,),
            TextField(
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Категория',
                border: InputBorder.none,
                contentPadding: EdgeInsetsGeometry.symmetric(vertical: 20, horizontal: 10),
              ),
            ),
            SizedBox(height: 10,),
            Row(
              children: [
                TextField(
                  onChanged: (value) {},
                  decoration: InputDecoration(
                    hintText: '500 ₽',
                    border: InputBorder.none,
                    contentPadding: EdgeInsetsGeometry.symmetric(vertical: 20, horizontal: 10),
                  ),
                ),
                SizedBox(width: 10,),
                TextField(
                  onChanged: (value) {},
                  decoration: InputDecoration(
                    hintText: 'Срок аренды',
                    border: InputBorder.none,
                    contentPadding: EdgeInsetsGeometry.symmetric(vertical: 20, horizontal: 10),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10,),
            TextField(
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Срок аренды',
                border: InputBorder.none,
                contentPadding: EdgeInsetsGeometry.symmetric(vertical: 20, horizontal: 10),
              ),
            ),
            SizedBox(height: 10,),
            TextField(
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Опишите товар, его состояние и условия аренды...',
                border: InputBorder.none,
                contentPadding: EdgeInsetsGeometry.symmetric(vertical: 20, horizontal: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}