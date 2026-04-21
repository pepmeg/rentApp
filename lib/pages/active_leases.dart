import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/colors.dart';

class ActiveLeases extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.only(left: 20, right: 20, top: 40),
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
                SizedBox(width: 5,),
                Text(
                  'Активные аренды',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                ),
              ],
            ),
            SizedBox(height: 15),
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
          ]
        ),
      ),
    );
  }
}