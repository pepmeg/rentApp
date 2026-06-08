import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lease_request.dart';
import '../models/user.dart';
import '../provider/AuthProvider.dart';
import '../provider/LeaseRequestProvider.dart';
import '../provider/activeLeasesProvider.dart';
import '../provider/basket_provider.dart';
import '../services/connectivityService.dart';
import '../services/product_service.dart';
import '../utils/avatar.dart';
import '../utils/snackbar_custom.dart';
import 'product_image.dart';
import '../pages/productScreen.dart';

class LeaseRequestCard extends StatelessWidget {
  final LeaseRequest request;
  final VoidCallback? onUserTap;

  const LeaseRequestCard({
    required this.request,
    this.onUserTap,
    super.key,
  });

  List<String> _getDisplayImages() {
    return request.images.isNotEmpty ? request.images : [];
  }

  Future<void> _onCardTap(BuildContext context) async {
    try {
      final product = await ProductService.getProductById(request.productId);
      if (product != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
        );
      }
    } catch (e) {}
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green.shade700;
    if (rating >= 2.5) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  void _showOfflineDialog(BuildContext context, VoidCallback retryAction) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Нет интернета', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text('Действие не выполнено. Попробовать снова?', style: TextStyle(color: theme.colorScheme.onSurface)),
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена', style: TextStyle(color: theme.colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              retryAction();
            },
            child: Text('Повторить', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    SnackBarCustom.show(context, message: 'Ошибка: $error');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayImages = _getDisplayImages();

    return Card(
      elevation: 2,
      shadowColor: theme.colorScheme.onSurface.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onCardTap(context),
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
                      images: displayImages,
                      width: 80,
                      height: 80,
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
                          request.productName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${request.pricePerDay} ₽ / день',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: theme.dividerColor,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: onUserTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(builder: (context) {
                        final requesterUser = UserModel(
                          uid: request.requesterId,
                          email: '',
                          firstName: request.requesterFirstName,
                          lastName: request.requesterLastName,
                          phoneNumber: '',
                          address: '',
                          avatarUrl: request.requesterAvatarPath,
                          role: 'user',
                        );
                        return buildUserAvatar(context,requesterUser, radius: 16);
                      }),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<UserModel?>(
                              future: context.read<AuthProvider>().getUserById(request.requesterId),
                              builder: (context, snapshot) {
                                final rating = snapshot.data?.rating ?? 5.0;
                                final ratingColor = _getRatingColor(rating);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: ratingColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: ratingColor.withAlpha(80), width: 0.5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star, size: 14, color: ratingColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: ratingColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            Text(
                              request.type == RequestType.completion
                                  ? '${request.requesterFirstName} ${request.requesterLastName} хочет завершить аренду'
                                  : '${request.requesterFirstName} ${request.requesterLastName} хочет арендовать',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (request.type == RequestType.lease)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final connectivity = context.read<ConnectivityService>();
                          if (!connectivity.hasInternet) {
                            _showOfflineDialog(context, () async {
                              await context.read<LeaseRequestProvider>().acceptRequest(
                                request.firestoreDocId,
                                context.read<ActiveLeasesProvider>(),
                              );
                            });
                            return;
                          }
                          try {
                            await context.read<LeaseRequestProvider>().acceptRequest(
                              request.firestoreDocId,
                              context.read<ActiveLeasesProvider>(),
                            );
                          } catch (e) {
                            _showErrorDialog(context, e.toString());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Принять', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final connectivity = context.read<ConnectivityService>();
                          if (!connectivity.hasInternet) {
                            _showOfflineDialog(context, () async {
                              await context.read<LeaseRequestProvider>().rejectRequest(
                                request.firestoreDocId,
                                leasesProvider: context.read<ActiveLeasesProvider>(),
                              );
                            });
                            return;
                          }
                          try {
                            await context.read<LeaseRequestProvider>().rejectRequest(
                              request.firestoreDocId,
                              leasesProvider: context.read<ActiveLeasesProvider>(),
                            );
                          } catch (e) {
                            _showErrorDialog(context, e.toString());
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Отклонить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                )
              else if (request.type == RequestType.completion)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final connectivity = context.read<ConnectivityService>();
                          if (!connectivity.hasInternet) {
                            _showOfflineDialog(context, () async {
                              await context.read<LeaseRequestProvider>().acceptCompletion(
                                request.firestoreDocId,
                                context.read<ActiveLeasesProvider>(),
                                context.read<BasketProvider>(),
                              );
                            });
                            return;
                          }
                          try {
                            await context.read<LeaseRequestProvider>().acceptCompletion(
                              request.firestoreDocId,
                              context.read<ActiveLeasesProvider>(),
                              context.read<BasketProvider>(),
                            );
                          } catch (e) {
                            _showErrorDialog(context, e.toString());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor.withOpacity(0.2),
                          foregroundColor: theme.colorScheme.onSurface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Подтвердить'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final connectivity = context.read<ConnectivityService>();
                          if (!connectivity.hasInternet) {
                            _showOfflineDialog(context, () async {
                              await context.read<LeaseRequestProvider>().rejectCompletion(
                                request.firestoreDocId,
                                context.read<ActiveLeasesProvider>(),
                              );
                            });
                            return;
                          }
                          try {
                            await context.read<LeaseRequestProvider>().rejectCompletion(
                              request.firestoreDocId,
                              context.read<ActiveLeasesProvider>(),
                            );
                          } catch (e) {
                            _showErrorDialog(context, e.toString());
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Отклонить'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}