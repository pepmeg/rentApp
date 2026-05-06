import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activeLease.dart';
import '../../models/admin_models/report.dart';
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
import 'package:intl/intl.dart';
import '../../utils/form_fields.dart';
import '../../utils/pagination.dart';
import '../../utils/snackbar_custom.dart';
import '../../pages/person.dart';

class AdminUsersTab extends StatefulWidget {
  final bool initialShowBlocked;
  const AdminUsersTab({super.key, this.initialShowBlocked = false});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> with PaginationMixin {
  bool _showBlockedOnly = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _showBlockedOnly = widget.initialShowBlocked;
  }

  @override
  int get paginationBatchSize => 12;

  @override
  List<dynamic> get paginationItems => _filteredUsers;

  List<UserModel> get _filteredUsers {
    final admin = context.read<AdminProvider>();
    admin.loadUsers();
    final allUsers = _showBlockedOnly
        ? admin.users.where((u) => u.blocked).toList()
        : admin.users;

    var users = _searchQuery.isEmpty
        ? allUsers.toList()
        : allUsers.where((u) {
      final name = '${u.firstName} ${u.lastName}'.toLowerCase();
      final email = u.email.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
    users.sort((a, b) => b.id.compareTo(a.id));
    return users;
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final allItems = _filteredUsers;
    final visibleItems = allItems.take(visibleCount).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
                resetPagination();
              },
              decoration: InputDecoration(
                hintText: 'Поиск',
                hintStyle: TextStyle(color: AppColors.oliveGray.withOpacity(0.5), fontSize: 16),
                prefixIcon: Icon(Icons.search, color: AppColors.copper),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              _buildFilterChip('Все', !_showBlockedOnly, () {
                setState(() => _showBlockedOnly = false);
                resetPagination();
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Заблокированные', _showBlockedOnly, () {
                setState(() => _showBlockedOnly = true);
                resetPagination();
              }),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: visibleItems.length,
            itemBuilder: (context, index) {
              final user = visibleItems[index];
              final isPrivileged = (user.role == 'admin' || user.role == 'support');
              final bool isClickable = !isPrivileged;

              int userLeasesCount = 0;
              if (!isPrivileged) {
                final leasesProvider = context.read<ActiveLeasesProvider>();
                userLeasesCount = leasesProvider.getLeasesForUser(user.id).length;
              }

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
                  subtitle: isPrivileged
                      ? null
                      : Text(
                    'Аренды: $userLeasesCount',
                    style: const TextStyle(color: AppColors.oliveGray),
                  ),
                  trailing: isPrivileged
                      ? null
                      : AppPopupMenuButton<String>(
                    backgroundColor: AppColors.spaceCream,
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
                      } else if (action == 'reports') {
                        _showUserReports(context, user.id);
                      }
                    },
                    items: [
                      if (!user.blocked)
                        const PopupMenuItem(value: 'block', child: Text('Заблокировать'))
                      else
                        const PopupMenuItem(value: 'unblock', child: Text('Разблокировать')),
                      const PopupMenuItem(value: 'history', child: Text('История сделок')),
                      PopupMenuItem(
                        value: 'reports',
                        child: Row(
                          children: [
                            Text('Жалобы${admin.getReportsRelatedToUser(user.id).isNotEmpty ? ' (${admin.getReportsRelatedToUser(user.id).length})' : ''}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: isClickable
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Profile(userId: user.id)),
                    );
                  }
                      : null,
                ),
              );
            },
          ),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(color: AppColors.copper)),
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
              return FutureBuilder<UserModel?>(
                future: context.read<AuthProvider>().getUserById(lease.ownerId),
                builder: (context, snapshot) {
                  final ownerName = snapshot.data != null
                      ? '${snapshot.data!.firstName} ${snapshot.data!.lastName}'
                      : 'Неизвестно';
                  final startDateFormatted = lease.startDate != null
                      ? DateFormat('dd.MM.yyyy').format(lease.startDate!)
                      : '—';
                  return ListTile(
                    dense: true,
                    title: Text(lease.name, style: const TextStyle(color: AppColors.oliveGray)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Владелец: $ownerName', style: TextStyle(color: AppColors.oliveGray.withOpacity(0.7))),
                        Text('Начало: $startDateFormatted', style: TextStyle(color: AppColors.oliveGray.withOpacity(0.7))),
                      ],
                    ),
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
    SnackBarCustom.show(context, message: 'Действие выполнено');
  }

  void _showUserReports(BuildContext context, int userId) {
    final admin = context.read<AdminProvider>();
    final reports = admin.getReportsRelatedToUser(userId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.whiteAntique,
        title: const Text('Жалобы на пользователя', style: TextStyle(color: AppColors.oliveGray)),
        content: SizedBox(
          width: double.maxFinite,
          child: reports.isEmpty
              ? Text('Жалоб нет', style: TextStyle(color: AppColors.oliveGray.withOpacity(0.5)))
              : ListView.builder(
            shrinkWrap: true,
            itemCount: reports.length,
            itemBuilder: (_, i) {
              final r = reports[i];
              final isOnUser = r.targetType == ReportTargetType.user;
              final productName = isOnUser
                  ? null
                  : ProductData.getProductById(r.productId!)?.name ?? 'Товар #${r.productId}';
              return FutureBuilder(
                future: context.read<AuthProvider>().getUserById(r.reporterId),
                builder: (ctx, snapshot) {
                  final reporterName = snapshot.data != null
                      ? '${snapshot.data!.firstName} ${snapshot.data!.lastName}'
                      : 'Пользователь ${r.reporterId}';
                  return ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(reporterName, style: TextStyle(color: AppColors.oliveGray)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOnUser ? AppColors.copper.withOpacity(0.2) : AppColors.lightGreen.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOnUser ? 'На пользователя' : 'На товар "$productName"',
                            style: TextStyle(fontSize: 12, color: AppColors.oliveGray),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.reason, style: TextStyle(color: AppColors.oliveGray.withOpacity(0.7))),
                        Text(DateFormat('dd.MM.yyyy HH:mm').format(r.createdAt),
                            style: TextStyle(fontSize: 12, color: AppColors.oliveGray.withOpacity(0.5))),
                      ],
                    ),
                  );
                },
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
}