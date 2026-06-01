import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../utils/avatar.dart';

class ProfileStatColumn extends StatelessWidget {
  final String value;
  final String label;
  const ProfileStatColumn({required this.value, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class ProfileStatCard extends StatelessWidget {
  final List<ProfileStatColumn> columns;
  const ProfileStatCard({required this.columns, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: columns,
      ),
    );
  }
}

class Badge extends StatelessWidget {
  final int count;
  const Badge({required this.count, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 25),
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(12.5),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}

class ProfileUserInfo extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final bool showPhone;

  const ProfileUserInfo({
    required this.user,
    this.onTap,
    this.showPhone = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          buildUserAvatar(user, radius: 50),
          const SizedBox(width: 30),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: theme.colorScheme.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: theme.colorScheme.onSurface),
                ),
                if (showPhone) ...[
                  const SizedBox(height: 5),
                  Text(
                    user.phoneNumber,
                    style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileAdsButton extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback onTap;

  const ProfileAdsButton({
    required this.count,
    required this.label,
    required this.onTap,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(Icons.list_alt_rounded, size: 22, color: theme.colorScheme.onSurface),
            const SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const Spacer(),
            Badge(count: count),
            const SizedBox(width: 15),
            Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.onSurface),
          ],
        ),
      ),
    );
  }
}