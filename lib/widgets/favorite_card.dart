import 'package:flutter/material.dart';
import 'package:untitled/utils/colors.dart';

class FavoriteCard extends StatelessWidget {
  final String name;
  final int price;
  final String image;
  final String location;

  const FavoriteCard({
    required this.name,
    required this.price,
    required this.image,
    required this.location,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.whiteAntique,
        child: Padding(
            padding: const EdgeInsetsGeometry.symmetric(
              vertical: 10,
              horizontal: 15,
            ),
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
            children:[ ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                image,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
          SizedBox(width: 20,),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: AppColors.oliveGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  '$price ₽ в день',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: AppColors.oliveGray,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w200,
                    color: AppColors.oliveGray,
                  ),
                ),
              ],
            ),
          ),
            Icon(
              Icons.heart_broken,
              size: 20,
              color: AppColors.spaceCream,
            ),
            ],
          ),
      ),
    );
  }
}
