import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/CompletedLease.dart';
import '../models/user.dart';
import '../pages/person.dart';
import '../utils/avatar.dart';
import 'product_image.dart';

class CompletedLeaseCard extends StatelessWidget {
  final CompletedLease lease;

  const CompletedLeaseCard({required this.lease, super.key});

  @override
  Widget build(BuildContext context) {
    final startFormatted = DateFormat('dd.MM.yyyy HH:mm').format(lease.startDate.toLocal());
    final endFormatted = DateFormat('dd.MM.yyyy HH:mm').format(lease.endDate.toLocal());
    final priceUnit = lease.isHourly ? '₽/час' : '₽/день';
    final theme = Theme.of(context);

    final ownerUser = UserModel(
      uid: lease.ownerId,
      email: '',
      firstName: lease.ownerName.split(' ').first,
      lastName: lease.ownerName.split(' ').length > 1 ? lease.ownerName.split(' ').last : '',
      phoneNumber: '',
      address: '',
      avatarUrl: lease.ownerAvatarUrl,
      role: 'user',
    );

    return Card(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/product', arguments: lease.productId);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ProductImage(
                      images: lease.images,
                      width: 70,
                      height: 70,
                      backgroundColor: theme.colorScheme.background,
                      cacheUrls: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lease.productName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Profile(userId: lease.ownerId),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              buildUserAvatar(ownerUser, radius: 10),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  lease.ownerName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$startFormatted — $endFormatted',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lease.isHourly
                          ? '${lease.pricePerDay} ₽/час × ${lease.units} ч.'
                          : '${lease.pricePerDay} ₽/день × ${lease.units} дн.${lease.extraHours > 0 ? ' + ${lease.extraHours} ч.' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '${lease.totalPrice} ₽',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}