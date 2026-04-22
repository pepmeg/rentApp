import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class BasketCard extends StatelessWidget {
  final int id;
  final String name;
  final int price;
  final String image;
  final int days;
  final Function(int) onDaysChanged;
  final VoidCallback onRemove;

  const BasketCard({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.days,
    required this.onDaysChanged,
    required this.onRemove,
    super.key,
  });

  String _getDaysWord(int days) {
    if (days % 100 >= 11 && days % 100 <= 19) return 'дней';
    switch (days % 10) {
      case 1:
        return 'день';
      case 2:
      case 3:
      case 4:
        return 'дня';
      default:
        return 'дней';
    }
  }

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
                          GestureDetector(
                            onTap: onRemove,
                            child: Icon(
                              Icons.delete_outline,
                              size: 30,
                              color: AppColors.oliveGray,
                            ),
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
                    GestureDetector(
                      onTap: () {
                        if (days > 1) {
                          onDaysChanged(days - 1);
                        }
                      },
                      child: Icon(
                        Icons.exposure_minus_1,
                        size: 15,
                        color: days > 1
                            ? AppColors.oliveGray
                            : AppColors.oliveGray.withOpacity(0.3),
                      ),
                    ),
                    SizedBox(width: 15,),
                    SizedBox(
                      width: 70,
                      child: Text(
                        '$days ${_getDaysWord(days)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: AppColors.oliveGray,
                        ),
                      ),
                    ),
                    SizedBox(width: 15,),
                    GestureDetector(
                      onTap: () {
                        if (days < 99) {
                          onDaysChanged(days + 1);
                        }
                      },
                      child: Icon(
                        Icons.plus_one,
                        size: 15,
                        color: days < 99
                            ? AppColors.oliveGray
                            : AppColors.oliveGray.withOpacity(0.3),
                      ),
                    ),
                  ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}

