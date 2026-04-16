import 'package:flutter/material.dart';
import 'package:untitled/utils/colors.dart';

class ProductCard extends StatelessWidget {

  final String name;
  final int price;
  final String location;
  final String image;

  const ProductCard({
    required this.name,
    required this.price,
    required this.location,
    required this.image,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.whiteAntique,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  image,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                  child: const Icon(
                    Icons.favorite_border,
                    color: AppColors.oliveGray,
                    size: 20,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    Icon(Icons.star, color: AppColors.yellowSchoolBus, size: 20,),
                    Text(
                      '4.8',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '$price ₽/день',
                  style: TextStyle(fontSize: 15, color: AppColors.oliveGray),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppColors.oliveGray),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(fontSize: 12, color: AppColors.oliveGray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}