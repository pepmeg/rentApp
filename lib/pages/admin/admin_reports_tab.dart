import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/admin_models/report.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../provider/bottom_nav_provider.dart';
import '../../services/product_service.dart';
import '../../provider/admin_provider.dart';
import '../../provider/AuthProvider.dart';
import '../../utils/pagination.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_field.dart';
import '../../widgets/filter_chip.dart';
import '../productScreen.dart';

class _ReportBundleData {
  final Map<String, UserModel> users;
  final Map<String, Product> products;

  _ReportBundleData({required this.users, required this.products});
}

class AdminReportsTab extends StatefulWidget {
  final ReportTargetType? initialTargetType;
  const AdminReportsTab({super.key, this.initialTargetType});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> with PaginationMixin {
  ReportTargetType? _filterTargetType;
  String _searchQuery = '';

  _ReportBundleData? _bundleData;
  bool _isLoadingBundle = false;
  String? _lastBundleKeys;

  @override
  void initState() {
    super.initState();
    _filterTargetType = widget.initialTargetType;
  }

  @override
  int get paginationBatchSize => 10;

  @override
  List<dynamic> get paginationItems => _filteredReports;

  List<Report> get _filteredReports {
    final admin = context.read<AdminProvider>();
    var reports = admin.reports.where((r) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!r.reason.toLowerCase().contains(query) &&
            !(r.productId?.toString().contains(query) ?? false) &&
            !(r.targetUserId?.toString().contains(query) ?? false)) {
          return false;
        }
      }
      if (_filterTargetType != null && r.targetType != _filterTargetType) {
        return false;
      }
      return true;
    }).toList();
    reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reports;
  }

  ({Set<String> userIds, Set<String> productIds}) _collectIds(List<Report> reports) {
    final Set<String> userIds = {};
    final Set<String> productIds = {};

    for (final r in reports) {
      if (r.reporterId.isNotEmpty) userIds.add(r.reporterId);
      if (r.targetUserId != null && r.targetUserId!.isNotEmpty) {
        userIds.add(r.targetUserId!);
      }
      if (r.targetType == ReportTargetType.product &&
          r.productId != null &&
          r.productId!.isNotEmpty) {
        productIds.add(r.productId!);
      }
    }
    return (userIds: userIds, productIds: productIds);
  }

  String _getBundleKey(List<Report> reports) {
    final ids = _collectIds(reports);
    return '${ids.userIds.toList()..sort()}_${ids.productIds.toList()..sort()}';
  }

  Future<_ReportBundleData> _loadBundle(List<Report> reports) async {
    final ids = _collectIds(reports);
    final auth = context.read<AuthProvider>();
    await auth.preloadUsers(ids.userIds.toList());

    final Map<String, UserModel> usersMap = {};
    for (final uid in ids.userIds) {
      final u = auth.getCachedUser(uid);
      if (u != null) usersMap[uid] = u;
    }

    Map<String, Product> productsMap = {};
    if (ids.productIds.isNotEmpty) {
      try {
        final products = await ProductService.getProductsByIds(ids.productIds.toList());
        for (final p in products) {
          productsMap[p.id] = p;
        }
      } catch (e) {
        debugPrint('Ошибка пакетной загрузки товаров: $e');
      }
    }

    return _ReportBundleData(users: usersMap, products: productsMap);
  }

  Future<void> _loadBundleIfNeeded(List<Report> reports) async {
    final currentKey = _getBundleKey(reports);
    if (_lastBundleKeys == currentKey && _bundleData != null) {
      return;
    }
    setState(() {
      _isLoadingBundle = true;
    });
    try {
      final bundle = await _loadBundle(reports);
      if (mounted) {
        setState(() {
          _bundleData = bundle;
          _lastBundleKeys = currentKey;
          _isLoadingBundle = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки bundle: $e');
      if (mounted) {
        setState(() {
          _isLoadingBundle = false;
        });
      }
    }
  }

  String _buildTargetLabel(Report report, _ReportBundleData bundle) {
    if (report.targetType == ReportTargetType.product && report.productId != null) {
      final product = bundle.products[report.productId!];
      if (product != null) {
        return 'На товар "${product.name}"';
      }
      return 'На товар #${report.productId}';
    } else if (report.targetType == ReportTargetType.user && report.targetUserId != null) {
      final user = bundle.users[report.targetUserId!];
      if (user != null) {
        return 'На пользователя ${user.firstName} ${user.lastName}';
      }
      return 'На пользователя #${report.targetUserId}';
    }
    return 'Неизвестно';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AdminProvider>();
    final auth = context.read<AuthProvider>();
    final allItems = _filteredReports;
    final visibleItems = allItems.take(visibleCount).toList();
    final currentUserId = auth.currentUser?.uid;
    final theme = Theme.of(context);
    if (visibleItems.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBundleIfNeeded(visibleItems);
      });
    }

    if (visibleItems.isEmpty) {
      return Column(
        children: [
          SearchField(
            hintText: 'Поиск жалоб',
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _lastBundleKeys = null;
                _bundleData = null;
                resetPagination();
              });
            },
          ),
          _buildFilterBar(theme),
          const Expanded(
            child: EmptyState(
              icon: Icons.report_off_outlined,
              title: 'Нет жалоб',
              subtitle: 'Жалобы на товары и пользователей будут отображаться здесь',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        SearchField(
          hintText: 'Поиск жалоб',
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _lastBundleKeys = null;
              _bundleData = null;
              resetPagination();
            });
          },
        ),
        _buildFilterBar(theme),
        Expanded(
          child: _isLoadingBundle && _bundleData == null
              ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
              : _bundleData == null
              ? const SizedBox.shrink()
              : _buildReportList(visibleItems, _bundleData!, currentUserId, theme),
        ),
      ],
    );
  }

  Widget _buildReportList(
      List<Report> visibleItems,
      _ReportBundleData bundle,
      String? currentUserId,
      ThemeData theme,
      ) {
    return ListView.builder(
      controller: scrollController,
      itemCount: visibleItems.length,
      itemBuilder: (context, index) {
        final report = visibleItems[index];
        final isProductReport = report.targetType == ReportTargetType.product;
        final reporter = bundle.users[report.reporterId];
        final reporterName = reporter != null
            ? '${reporter.firstName} ${reporter.lastName}'
            : 'Пользователь ${report.reporterId}';
        final targetLabel = _buildTargetLabel(report, bundle);
        final isUnread = currentUserId != null && !report.readByUserIds.contains(currentUserId);

        return Card(
          elevation: 1,
          shadowColor: theme.colorScheme.onSurface.withOpacity(0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _navigateToTarget(
                    context,
                    report: report,
                    isProductReport: isProductReport,
                    bundle: bundle,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isProductReport
                              ? theme.primaryColor.withOpacity(0.2)
                              : theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          isProductReport ? Icons.shopping_bag : Icons.person,
                          color: theme.colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                      if (isUnread)
                        Positioned(
                          top: -4,
                          left: -4,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      if (currentUserId != null && !report.readByUserIds.contains(currentUserId)) {
                        await context
                            .read<AdminProvider>()
                            .markReportAsRead(report.firestoreDocId, currentUserId);
                      }
                      _showReportDialog(
                        context,
                        report: report,
                        reporter: reporter,
                        targetLabel: targetLabel,
                        isProductReport: isProductReport,
                        currentUserId: currentUserId,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reporterName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  targetLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  report.reason,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(report.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          AppFilterChip(
            label: 'Все',
            isSelected: _filterTargetType == null,
            onTap: () {
              setState(() {
                _filterTargetType = null;
                _lastBundleKeys = null;
                _bundleData = null;
                resetPagination();
              });
            },
          ),
          const SizedBox(width: 8),
          AppFilterChip(
            label: 'Товары',
            isSelected: _filterTargetType == ReportTargetType.product,
            onTap: () {
              setState(() {
                _filterTargetType = ReportTargetType.product;
                _lastBundleKeys = null;
                _bundleData = null;
                resetPagination();
              });
            },
          ),
          const SizedBox(width: 8),
          AppFilterChip(
            label: 'Пользователи',
            isSelected: _filterTargetType == ReportTargetType.user,
            onTap: () {
              setState(() {
                _filterTargetType = ReportTargetType.user;
                _lastBundleKeys = null;
                _bundleData = null;
                resetPagination();
              });
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final dateFormat = (date.year == now.year) ? 'dd.MM' : 'dd.MM.yyyy';
    return DateFormat(dateFormat).format(date);
  }

  Future<void> _showReportDialog(
      BuildContext context, {
        required Report report,
        required UserModel? reporter,
        required String targetLabel,
        required bool isProductReport,
        String? currentUserId,
      }) async {
    if (currentUserId != null && !report.readByUserIds.contains(currentUserId)) {
      report.readByUserIds.add(currentUserId);
      await context.read<AdminProvider>().markReportAsRead(report.firestoreDocId, currentUserId);
    }
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        title: Row(
          children: [
            Icon(isProductReport ? Icons.shopping_bag : Icons.person, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(
              isProductReport ? 'Жалоба на товар' : 'Жалоба на пользователя',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Отправитель: ${reporter != null ? '${reporter.firstName} ${reporter.lastName}' : report.reporterId}',
                style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 10),
              Text('Объект:', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text(targetLabel, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8))),
              const SizedBox(height: 10),
              Text('Причина:', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text(report.reason, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8))),
              const SizedBox(height: 10),
              Text(
                'Дата: ${DateFormat('dd.MM.yyyy HH:mm').format(report.createdAt)}',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: theme.primaryColor),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _navigateToTarget(
      BuildContext context, {
        required Report report,
        required bool isProductReport,
        required _ReportBundleData bundle,
      }) async {
    if (isProductReport && report.productId != null) {
      final productId = report.productId!;
      Product? product = bundle.products[productId];
      if (product == null) {
        product = await ProductService.getProductById(productId);
      }
      if (mounted && product != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen(product: product!)));
      }
    } else if (!isProductReport && report.targetUserId != null) {
      if (mounted) {
        final bottomNavProvider = context.read<BottomNavProvider>();
        bottomNavProvider.showUserProfile(report.targetUserId!);
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }
}