import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/AuthProvider.dart';
import '../models/user.dart';
import '../widgets/profile_widget/profile_own.dart';
import '../widgets/profile_widget/profile_public.dart';

class Profile extends StatelessWidget {
  final int? userId;

  const Profile({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (userId == null || userId == currentUser?.id) {
      return ProfileOwn(user: currentUser!);
    }

    return Scaffold(
      body: FutureBuilder<UserModel?>(
        future: authProvider.getUserById(userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          if (user == null) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(title: const Text('Пользователь не найден')),
              body: const Center(child: Text('Данные недоступны')),
            );
          }
          return ProfilePublic(user: user);
        },
      ),
    );
  }
}