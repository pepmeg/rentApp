import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/models/user.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/pages/person.dart';

import '../../provider/bottom_nav_provider.dart';

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

        return GestureDetector(
            onTap: () {
              context.read<BottomNavProvider>().showUserProfile(owner.id);
              Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.oliveGray.withOpacity(0.1),
                  backgroundImage: owner.avatarPath != null
                      ? (owner.avatarPath!.startsWith('assets/')
                      ? AssetImage(owner.avatarPath!)
                      : FileImage(File(owner.avatarPath!)))
                      : null,
                  child: owner.avatarPath == null
                      ? Icon(Icons.person, color: AppColors.oliveGray, size: 50)
                      : null,
                ),
                const SizedBox(width: 30),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${owner.firstName} ${owner.lastName}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      Text('${owner.phoneNumber}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}