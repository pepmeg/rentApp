import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/activeLease.dart';
import '../../models/admin_models/report.dart';
import '../../models/lease_request.dart';
import '../../models/user.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/admin_provider.dart';
import '../../provider/activeLeasesProvider.dart';
import '../../provider/LeaseRequestProvider.dart';
import '../../provider/basket_provider.dart';
import '../../provider/bottom_nav_provider.dart';
import '../../services/product_service.dart';
import '../../utils/avatar.dart';
import '../../utils/form_fields.dart';
import '../../utils/pagination.dart';
import '../../utils/snackbar_custom.dart';

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
    users.sort((a, b) => b.uid.compareTo(a.uid));
    return users;
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final allItems = _filteredUsers;
    final visibleItems = allItems.take(visibleCount).toList();
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              color: theme.colorScheme.surface,
              child: TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  resetPagination();
                },
                decoration: InputDecoration(
                  hintText: 'Поиск',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 16),
                  prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              _buildFilterChip(theme, 'Все', !_showBlockedOnly, () {
                setState(() => _showBlockedOnly = false);
                resetPagination();
              }),
              const SizedBox(width: 8),
              _buildFilterChip(theme, 'Заблокированные', _showBlockedOnly, () {
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

              int userRentedCount = 0;
              if (!isPrivileged) {
                final leasesProvider = context.read<ActiveLeasesProvider>();
                userRentedCount = leasesProvider.getRentedLeasesForUser(user.uid).length;
              }

              return Card(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: buildUserAvatar(user, radius: 24),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${user.firstName} ${user.lastName}',
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.blocked) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.block, size: 18, color: theme.colorScheme.error),
                        const SizedBox(width: 2),
                        Text(
                          '(заблокирован)',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: isPrivileged
                      ? null
                      : Text(
                    'Арендовал: $userRentedCount',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  trailing: isPrivileged
                      ? null
                      : AppPopupMenuButton<String>(
                    backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                    onSelected: (action) {
                      if (action == 'block') {
                        admin.blockUser(user.uid);
                        _cancelUserLeases(context, user.uid);
                        _hideUserProducts(user.uid);
                        _forceLogoutIfCurrentUser(context, user.uid);
                      } else if (action == 'unblock') {
                        admin.unblockUser(user.uid);
                        _restoreUserProducts(user.uid);
                      } else if (action == 'history') {
                        _showUserHistory(context, user.uid);
                      } else if (action == 'reports') {
                        _showUserReports(context, user.uid);
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
                            Text('Жалобы${admin.getReportsRelatedToUser(user.uid).isNotEmpty ? ' (${admin.getReportsRelatedToUser(user.uid).length})' : ''}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: isClickable
                      ? () {
                    context.read<BottomNavProvider>().showUserProfile(user.uid);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                      : null,
                ),
              );
            },
          ),
        ),
        if (isLoading)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(color: theme.primaryColor)),
          ),
      ],
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor: selected ? theme.primaryColor.withOpacity(0.1) : (theme.cardTheme.color ?? theme.colorScheme.surface),
        labelStyle: TextStyle(
          color: selected ? theme.primaryColor : theme.colorScheme.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  void _forceLogoutIfCurrentUser(BuildContext context, String userId) {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser?.uid == userId) {
      auth.logout().then((_) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    }
  }

  void _cancelUserLeases(BuildContext context, String userId) {
    final leases = context.read<ActiveLeasesProvider>().getRentedLeasesForUser(userId);
    final requestProvider = context.read<LeaseRequestProvider>();
    for (final lease in leases) {
      if (lease.status == LeaseStatus.active || lease.status == LeaseStatus.pending) {
        context.read<ActiveLeasesProvider>().finishLease(lease.productId);
        final requests = requestProvider.requests;
        final related = requests.where((r) => r.productId == lease.productId && r.status == RequestStatus.pending).toList();
        for (final req in related) {
          requestProvider.rejectRequest(
            req.firestoreDocId,
            leasesProvider: context.read<ActiveLeasesProvider>(),
          );
        }
      }
    }
  }

  Future<void> _hideUserProducts(String userId) async {
    try {
      final products = await ProductService.getAllProducts(ownerId: userId);
      for (final product in products) {
        await ProductService.updateProductStatus(product.id, 'hidden');
      }
    } catch (e) {
      debugPrint('Ошибка скрытия товаров: $e');
    }
  }

  Future<void> _restoreUserProducts(String userId) async {
    try {
      final products = await ProductService.getAllProducts(ownerId: userId);
      for (final product in products) {
        await ProductService.updateProductStatus(product.id, 'active');
      }
    } catch (e) {
      debugPrint('Ошибка восстановления товаров: $e');
    }
  }

  void _showUserHistory(BuildContext context, String userId) {
    final leases = context.read<ActiveLeasesProvider>().getRentedLeasesForUser(userId);
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        title: Text('История аренд', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: SizedBox(
          width: double.maxFinite,
          child: leases.isEmpty
              ? Text('Нет аренд', style: TextStyle(color: theme.colorScheme.onSurface))
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
                    title: Text(lease.name, style: TextStyle(color: theme.colorScheme.onSurface)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Владелец: $ownerName', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                        Text('Начало: $startDateFormatted', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
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
            child: Text('Закрыть', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _performLeaseAction(BuildContext context, ActiveLease lease, String action, String userId) {
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
          if (related != null) requestProvider.rejectRequest(
            related.firestoreDocId,
            leasesProvider: context.read<ActiveLeasesProvider>(),
          );
        } else if (lease.status == LeaseStatus.active) {
          leasesProvider.requestCompleteLease(lease.productId);
          requestProvider.addRequest(
            LeaseRequest(
              firestoreDocId: '',
              productId: lease.productId,
              productName: lease.name,
              pricePerDay: lease.pricePerDay,
              totalDays: lease.totalDays,
              requesterId: userId,
              requesterFirstName: lease.userFirstName,
              requesterLastName: lease.userLastName,
              requesterAvatarPath: lease.userAvatarUrl,
              ownerId: lease.ownerId,
              type: RequestType.completion,
              isHourly: lease.isHourly,
              requesterRating: lease.requesterRating,
            ),
            leasesProvider: context.read<ActiveLeasesProvider>(),
          );
          final completionRequest = requestProvider.requests.last;
          requestProvider.acceptCompletion(
            completionRequest.firestoreDocId,
            leasesProvider,
            context.read<BasketProvider>(),
          );
        }
        break;
      case 'complete':
        if (lease.status == LeaseStatus.active) {
          leasesProvider.requestCompleteLease(lease.productId);
          requestProvider.addRequest(
            LeaseRequest(
              firestoreDocId: '',
              productId: lease.productId,
              productName: lease.name,
              pricePerDay: lease.pricePerDay,
              totalDays: lease.totalDays,
              requesterId: userId,
              requesterFirstName: lease.userFirstName,
              requesterLastName: lease.userLastName,
              requesterAvatarPath: lease.userAvatarUrl,
              ownerId: lease.ownerId,
              type: RequestType.completion,
              isHourly: lease.isHourly,
              requesterRating: lease.requesterRating,
            ),
            leasesProvider: context.read<ActiveLeasesProvider>(),
          );
          final completionRequest = requestProvider.requests.last;
          requestProvider.acceptCompletion(
            completionRequest.firestoreDocId,
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

  void _showUserReports(BuildContext context, String userId) {
    final admin = context.read<AdminProvider>();
    admin.loadUserProducts(userId);
    final reports = admin.getReportsRelatedToUser(userId);
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        title: Text('Жалобы на пользователя', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: SizedBox(
          width: double.maxFinite,
          child: reports.isEmpty
              ? Text('Жалоб нет', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)))
              : ListView.builder(
            shrinkWrap: true,
            itemCount: reports.length,
            itemBuilder: (_, i) {
              final r = reports[i];
              final isOnUser = r.targetType == ReportTargetType.user;
              return FutureBuilder<dynamic>(
                future: isOnUser
                    ? Future.value(null)
                    : ProductService.getProductById(r.productId ?? ''),
                builder: (ctx, snapshot) {
                  final productName = snapshot.data?.name ?? 'Товар #${r.productId}';
                  return FutureBuilder<UserModel?>(
                    future: context.read<AuthProvider>().getUserById(r.reporterId),
                    builder: (ctx, reporterSnapshot) {
                      final reporterName = reporterSnapshot.data != null
                          ? '${reporterSnapshot.data!.firstName} ${reporterSnapshot.data!.lastName}'
                          : 'Пользователь ${r.reporterId}';
                      return ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(reporterName, style: TextStyle(color: theme.colorScheme.onSurface)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOnUser ? theme.primaryColor.withOpacity(0.1) : theme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isOnUser ? 'На пользователя' : 'На товар "$productName"',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.reason, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                            Text(DateFormat('dd.MM.yyyy HH:mm').format(r.createdAt),
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Закрыть', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }
}