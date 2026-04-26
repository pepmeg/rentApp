import 'dart:io';
import 'package:flutter/material.dart';
import 'package:untitled/models/user.dart';
import 'package:untitled/utils/colors.dart';

class ProductOwnerInfo extends StatelessWidget {
  final Future<UserModel?> futureOwner;

  const ProductOwnerInfo({required this.futureOwner, super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: futureOwner,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final owner = snapshot.data;
        if (owner == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: owner.avatarPath != null
                    ? Image.file(File(owner.avatarPath!), height: 100, width: 100, fit: BoxFit.cover)
                    : Image.asset('assets/silly_cat.jpg', height: 100, width: 100, fit: BoxFit.cover),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${owner.firstName} ${owner.lastName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray)),
                    const SizedBox(height: 5),
                    Text('${owner.phoneNumber}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray)),
                    const SizedBox(height: 5),
                    Text('${owner.address}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray), softWrap: true, overflow: TextOverflow.visible),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}