import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/bottom_nav_provider.dart';
import '../../utils/avatar.dart';
import '../../utils/colors.dart';

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
            final isUser = context.read<AuthProvider>().isUser;
            context.read<BottomNavProvider>().showUserProfile(owner.id, isUser: isUser);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildUserAvatar(owner, radius: 50),
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