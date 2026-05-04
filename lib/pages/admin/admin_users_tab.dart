import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activeLease.dart';
import '../../models/lease_request.dart';
import '../../models/user.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/admin_provider.dart';
import '../../provider/activeLeasesProvider.dart';
import '../../provider/LeaseRequestProvider.dart';
import '../../provider/basket_provider.dart';
import '../../provider/chat_provider.dart';
import '../../data/product_data.dart';
import '../../utils/avatar.dart';
import '../../utils/colors.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  bool _showBlockedOnly = false;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    admin.loadUsers();
    final List<UserModel> users = _showBlockedOnly
        ? admin.users.where((u) => u.blocked).toList()
        : admin.users;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('Все', !_showBlockedOnly, () {
                setState(() => _showBlockedOnly = false);
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Заблокированные', _showBlockedOnly, () {
                setState(() => _showBlockedOnly = true);
              }),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isPrivileged = (user.role == 'admin' || user.role == 'support');
              return Card(
                color: AppColors.whiteAntique,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: buildUserAvatar(user, radius: 24),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(color: AppColors.oliveGray),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.blocked) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.block, size: 18, color: Colors.redAccent),
                        const SizedBox(width: 2),
                        Text('(заблокирован)',
                            style: TextStyle(fontSize: 12, color: AppColors.oliveGray.withOpacity(0.7))),
                      ],
                    ],
                  ),
                  subtitle: const Text('Аренды: —', style: TextStyle(color: AppColors.oliveGray)),
                  trailing: isPrivileged
                      ? null
                      : PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'block') {
                        admin.blockUser(user.id);
                        _cancelUserLeases(context, user.id);
                        _hideUserProducts(user.id);
                        _forceLogoutIfCurrentUser(context, user.id);
                      } else if (action == 'unblock') {
                        admin.unblockUser(user.id);
                        _restoreUserProducts(user.id);
                      } else if (action == 'history') {
                        _showUserHistory(context, user.id);
                      }
                    },
                    itemBuilder: (context) => [
                      if (!user.blocked)
                        const PopupMenuItem(value: 'block', child: Text('Заблокировать'))
                      else
                        const PopupMenuItem(value: 'unblock', child: Text('Разблокировать')),
                      const PopupMenuItem(value: 'history', child: Text('История сделок')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor: selected ? AppColors.copper.withOpacity(0.2) : AppColors.spaceCream,
        labelStyle: TextStyle(
          color: selected ? AppColors.copper : AppColors.oliveGray,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  void _forceLogoutIfCurrentUser(BuildContext context, int userId) {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser?.id == userId) {
      auth.logout(chatProvider: context.read<ChatProvider>()).then((_) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    }
  }

  void _cancelUserLeases(BuildContext context, int userId) {
    final leases = context.read<ActiveLeasesProvider>().getLeasesForUser(userId);
    final requestProvider = context.read<LeaseRequestProvider>();
    for (final lease in leases) {
      if (lease.status == LeaseStatus.active || lease.status == LeaseStatus.pending) {
        context.read<ActiveLeasesProvider>().finishLease(lease.productId);
        final requests = requestProvider.requests;
        final related = requests.where((r) => r.productId == lease.productId && r.status == RequestStatus.pending).toList();
        for (final req in related) {
          requestProvider.rejectRequest(req.id);
        }
      }
    }
  }

  void _hideUserProducts(int userId) {
    final products = ProductData.products.where((p) => p.ownerId == userId);
    for (final product in products) {
      ProductData.updateProductStatus(product.id, 'hidden');
    }
  }

  void _restoreUserProducts(int userId) {
    final products = ProductData.products.where((p) => p.ownerId == userId);
    for (final product in products) {
      ProductData.updateProductStatus(product.id, 'active');
    }
  }

  void _showUserHistory(BuildContext context, int userId) {
    final leases = context.read<ActiveLeasesProvider>().getLeasesForUser(userId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.whiteAntique,
        title: const Text('История аренд', style: TextStyle(color: AppColors.oliveGray)),
        content: SizedBox(
          width: double.maxFinite,
          child: leases.isEmpty
              ? const Text('Нет аренд', style: TextStyle(color: AppColors.oliveGray))
              : ListView.builder(
            shrinkWrap: true,
            itemCount: leases.length,
            itemBuilder: (_, i) {
              final lease = leases[i];
              return ListTile(
                title: Text(lease.name),
                subtitle: Text('Статус: ${lease.status.toString().split('.').last}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    Navigator.pop(ctx);
                    _performLeaseAction(context, lease, action, userId);
                  },
                  itemBuilder: (_) => [
                    if (lease.status == LeaseStatus.active || lease.status == LeaseStatus.pending)
                      const PopupMenuItem(value: 'cancel', child: Text('Отменить')),
                    if (lease.status == LeaseStatus.active)
                      const PopupMenuItem(value: 'complete', child: Text('Завершить')),
                    const PopupMenuItem(value: 'delete', child: Text('Удалить')),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть', style: TextStyle(color: AppColors.copper)),
          ),
        ],
      ),
    );
  }

  void _performLeaseAction(BuildContext context, ActiveLease lease, String action, int userId) {
    final leasesProvider = context.read<ActiveLeasesProvider>();
    final requestProvider = context.read<LeaseRequestProvider>();

    switch (action) {
      case 'cancel':
        if (lease.status == LeaseStatus.pending) {
          leasesProvider.removePendingLeaseByProductId(lease.productId);
          final requests = requestProvider.requests;
          final related = requests.cast<LeaseRequest?>().firstWhere(
                (r) => r!.productId == lease.productId && r.status == RequestStatus.pending,
            orElse: () => null,
          );
          if (related != null) requestProvider.rejectRequest(related.id);
        } else if (lease.status == LeaseStatus.active) {
          leasesProvider.requestCompleteLease(lease.productId);
          requestProvider.addRequest(LeaseRequest(
            id: DateTime.now().millisecondsSinceEpoch,
            productId: lease.productId,
            productName: lease.name,
            pricePerDay: lease.pricePerDay,
            totalDays: lease.totalDays,
            requesterId: userId,
            requesterFirstName: lease.userFirstName,
            requesterLastName: lease.userLastName,
            requesterAvatarPath: lease.userAvatarPath,
            ownerId: lease.ownerId,
            type: RequestType.completion,
          ));
          final completionRequest = requestProvider.requests.last;
          requestProvider.acceptCompletion(
            completionRequest.id,
            leasesProvider,
            context.read<BasketProvider>(),
          );
        }
        break;
      case 'complete':
        if (lease.status == LeaseStatus.active) {
          leasesProvider.requestCompleteLease(lease.productId);
          requestProvider.addRequest(LeaseRequest(
            id: DateTime.now().millisecondsSinceEpoch,
            productId: lease.productId,
            productName: lease.name,
            pricePerDay: lease.pricePerDay,
            totalDays: lease.totalDays,
            requesterId: userId,
            requesterFirstName: lease.userFirstName,
            requesterLastName: lease.userLastName,
            requesterAvatarPath: lease.userAvatarPath,
            ownerId: lease.ownerId,
            type: RequestType.completion,
          ));
          final completionRequest = requestProvider.requests.last;
          requestProvider.acceptCompletion(
            completionRequest.id,
            leasesProvider,
            context.read<BasketProvider>(),
          );
        }
        break;
      case 'delete':
        leasesProvider.finishLease(lease.productId);
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Действие выполнено')));
  }
}