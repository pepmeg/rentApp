import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/models/product.dart';
import 'package:untitled/models/lease_request.dart';
import 'package:untitled/provider/AuthProvider.dart';
import 'package:untitled/provider/LeaseRequestProvider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/utils/snackbar_custom.dart';

class ProductInfoSection extends StatelessWidget {
  final Product product;

  const ProductInfoSection({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: AppColors.oliveGray,
                  ),
                ),
              ),
              Text(
                '${product.price} ₽',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.oliveGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.star, size: 25, color: AppColors.yellowSchoolBus),
              const SizedBox(width: 3),
              const Text('4.8', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: AppColors.oliveGray)),
              const Spacer(),
              Text('за день', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray.withOpacity(0.5))),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              final user = context.read<AuthProvider>().currentUser;
              if (user == null) return;

              final request = LeaseRequest(
                id: DateTime.now().millisecondsSinceEpoch,
                productId: product.id,
                productName: product.name,
                pricePerDay: product.price,
                totalDays: 1,
                requesterId: user.id,
                requesterFirstName: user.firstName,
                requesterLastName: user.lastName,
                requesterAvatarPath: user.avatarPath,
                ownerId: product.ownerId,
                images: product.images,
              );

              context.read<LeaseRequestProvider>().addRequest(request);
              SnackBarCustom.show(context, message: 'Запрос на аренду отправлен');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.copper,
              foregroundColor: AppColors.spaceCream,
              padding: const EdgeInsets.symmetric(vertical: 5),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('Арендовать', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}