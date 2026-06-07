import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/activeLease.dart';
import '../../models/admin_models/report.dart';
import '../../models/lease_request.dart';
import '../../models/product.dart';
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
import '../../widgets/search_field.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/filter_chip.dart';

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
        SearchField(
          hintText: 'Поиск пользователей',
          onChanged: (value) {
            setState(() => _searchQuery = value);
            resetPagination();
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              AppFilterChip(
                label: 'Все',
                isSelected: !_showBlockedOnly,
                onTap: () {
                  setState(() => _showBlockedOnly = false);
                  resetPagination();
                },
              ),
              const SizedBox(width: 8),
              AppFilterChip(
                label: 'Заблокированные',
                isSelected: _showBlockedOnly,
                onTap: () {
                  setState(() => _showBlockedOnly = true);
                  resetPagination();
                },
              ),
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
                      if (action == 'block' || action == 'unblock') {
                        _confirmBlockUser(context, user.uid, action == 'block');
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

  Future<void> _confirmBlockUser(BuildContext context, String userId, bool block) async {
    final confirm = await showConfirmDialog(
      context,
      title: block ? 'Заблокировать пользователя?' : 'Разблокировать пользователя?',
      message: block
          ? 'Пользователь не сможет пользоваться приложением, а его товары будут скрыты.'
          : 'Пользователь снова получит доступ к приложению.',
      confirmText: block ? 'Заблокировать' : 'Разблокировать',
      icon: block ? Icons.block : Icons.check_circle_outline,
      isDestructive: block,
    );

    if (confirm == true && mounted) {
      final admin = context.read<AdminProvider>();
      if (block) {
        admin.blockUser(userId);
        _cancelUserLeases(context, userId);
        _hideUserProducts(userId);
        _forceLogoutIfCurrentUser(context, userId);
      } else {
        admin.unblockUser(userId);
        _restoreUserProducts(userId);
      }
    }
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

  void _showUserHistory(BuildContext context, String userId) async {
    final leases = context.read<ActiveLeasesProvider>().getRentedLeasesForUser(userId);
    final auth = context.read<AuthProvider>();
    final theme = Theme.of(context);
    final ownerIds = leases.map((l) => l.ownerId).toSet().toList();
    await auth.preloadUsers(ownerIds);

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
              final owner = auth.getCachedUser(lease.ownerId);
              final ownerName = owner != null
                  ? '${owner.firstName} ${owner.lastName}'
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

  void _showUserReports(BuildContext context, String userId) async {
    final admin = context.read<AdminProvider>();
    await admin.loadUserProducts(userId);
    final reports = admin.getReportsRelatedToUser(userId);
    final auth = context.read<AuthProvider>();
    final theme = Theme.of(context);

    if (reports.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          title: Text('Жалобы на пользователя', style: TextStyle(color: theme.colorScheme.onSurface)),
          content: Text('Жалоб нет', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Закрыть', style: TextStyle(color: theme.primaryColor)),
            ),
          ],
        ),
      );
      return;
    }
    final reporterIds = reports.map((r) => r.reporterId).toSet().toList();
    final productIds = reports.where((r) => r.productId != null).map((r) => r.productId!).toSet().toList();
    await auth.preloadUsers(reporterIds);
    Map<String, Product> productMap = {};
    if (productIds.isNotEmpty) {
      final products = await ProductService.getProductsByIds(productIds);
      for (final p in products) {
        productMap[p.id] = p;
      }
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        title: Text('Жалобы на пользователя', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: reports.length,
            itemBuilder: (_, i) {
              final r = reports[i];
              final isOnUser = r.targetType == ReportTargetType.user;
              final reporter = auth.getCachedUser(r.reporterId);
              final reporterName = reporter != null
                  ? '${reporter.firstName} ${reporter.lastName}'
                  : 'Пользователь ${r.reporterId}';
              final product = r.productId != null ? productMap[r.productId] : null;
              final productName = product?.name ?? 'Товар #${r.productId}';
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