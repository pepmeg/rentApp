import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:untitled/utils/colors.dart';

class Add_Product extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 24, color: AppColors.oliveGray),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 20,),
                const Text(
                  'Добавить товар',
                  style: TextStyle(fontSize: 24,fontWeight: FontWeight.normal, color: AppColors.oliveGray),
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
                        width: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.whiteAntique,
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    );
                  }
              ),
            ),
            const SizedBox(height: 10,),
            TextField(
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Название товара',
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
              ),
            ),
            SizedBox(height: 10,),
            TextField(
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Категория',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.oliveGray, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              ),
            ),
            SizedBox(height: 10,),
            Row(
              children: [
                Expanded(child: TextField(
                  onChanged: (value) {},
                  decoration: InputDecoration(
                    hintText: '500 ₽',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.oliveGray, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  ),
                ),
                ),

                SizedBox(width: 10,),
                Expanded(child: TextField(
                  onChanged: (value) {},
                  decoration: InputDecoration(
                    hintText: 'Срок аренды',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.oliveGray, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  ),
                ),
                ),
              ],
            ),
            SizedBox(height: 10,),
            TextField(
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Город, район',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.oliveGray, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              ),
            ),
            SizedBox(height: 10,),
            TextField(
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Опишите товар, его состояние и условия аренды...',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.oliveGray, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                'Создать',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}