import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/bottom_nav_provider.dart';
import '../../utils/avatar.dart';

class ProductOwnerInfo extends StatelessWidget {
  final String ownerId;
  static final Map<String, Future<UserModel?>> _userFutures = {};
  const ProductOwnerInfo({required this.ownerId, super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final future = _getUserFuture(ownerId, authProvider);
    final theme = Theme.of(context);

    return FutureBuilder<UserModel?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final owner = snapshot.data;
        if (owner == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            context.read<BottomNavProvider>().showUserProfile(owner.uid);
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildUserAvatar(context,owner, radius: 50),
                const SizedBox(width: 30),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${owner.firstName} ${owner.lastName}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        owner.phoneNumber,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Future<UserModel?> _getUserFuture(String uid, AuthProvider authProvider) {
    if (_userFutures.containsKey(uid)) {
      return _userFutures[uid]!;
    }
    final future = authProvider.getUserById(uid);
    _userFutures[uid] = future;
    return future;
  }
}