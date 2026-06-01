import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activeLease.dart';
import '../models/user.dart';
import '../provider/bottom_nav_provider.dart';
import '../utils/avatar.dart';
import 'product_image.dart';

class UserOrdersCard extends StatelessWidget {
  final String id;
  final String name;
  final int price;
  final List<String> images;
  final String location;
  final DateTime createdAt;
  final ActiveLease? activeLease;
  final bool isPricePerHour;
  final VoidCallback onEdit;
  final bool isOwner;
  final String moderationStatus;
  final VoidCallback? onTap;

  const UserOrdersCard({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.location,
    required this.createdAt,
    this.activeLease,
    required this.isPricePerHour,
    required this.onEdit,
    this.isOwner = false,
    this.moderationStatus = 'active',
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd.MM.yyyy').format(createdAt);
    final theme = Theme.of(context);

    return Card(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImage(
                    images: images,
                    width: 100,
                    height: 100,
                    backgroundColor: theme.colorScheme.surface,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPricePerHour ? '$price ₽/час' : '$price ₽/день',
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: theme.colorScheme.onSurface),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Дата выставления: $dateFormatted',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOwner)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (moderationStatus == 'hidden')
                          Row(
                            children: [
                              Icon(Icons.visibility_off, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                'Скрыт',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        GestureDetector(
                          onTap: onEdit,
                          child: Icon(Icons.edit, color: theme.colorScheme.onSurface, size: 20),
                        ),
                      ],
                    ),
                ],
              ),
              if (activeLease != null) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    context.read<BottomNavProvider>().showUserProfile(activeLease!.userId);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Builder(builder: (context) {
                          final leaseUser = UserModel(
                            uid: activeLease!.userId,
                            email: '',
                            firstName: activeLease!.userFirstName,
                            lastName: activeLease!.userLastName,
                            phoneNumber: '',
                            address: '',
                            avatarUrl: activeLease!.userAvatarUrl,
                            role: 'user',
                          );
                          return buildUserAvatar(leaseUser, radius: 16);
                        }),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Арендует: ${activeLease!.userFirstName} ${activeLease!.userLastName}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurface),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}