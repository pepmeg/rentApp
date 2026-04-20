import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class BasketCard extends StatelessWidget {
  final String name;
  final int price;
  final String image;
  final int days;

  const BasketCard ({
    required this.name,
    required this.image,
    required this.price,
    required this.days,
    super.key,
});

  @override
  Widget build(BuildContext context){
    return Card(
      color: AppColors.whiteAntique,
      child: Container(
        padding: EdgeInsetsGeometry.all(25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: AppColors.whiteAntique,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    image,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
                              color: AppColors.oliveGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Spacer(),
                          Icon(
                            Icons.shopping_basket,
                            size: 30,
                            color: AppColors.oliveGray,
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Text(
                        '$price ₽ за день',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w100,
                          color: AppColors.oliveGray,
                        ),
                      ),
                    ],
                  ),
                )

              ],
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: AppColors.spaceCream,
              ),
              child: Row(
                  children: [
                    Text(
                      'Срок аренды',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                    ),
                    Spacer(),
                    Icon(Icons.plus_one, size: 15, color: AppColors.oliveGray,),
                    SizedBox(width: 15,),
                    Text(
                      '$days дня',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                    ),
                    SizedBox(width: 15,),
                    Icon(Icons.exposure_minus_1, size: 15, color: AppColors.oliveGray,),
                  ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}

