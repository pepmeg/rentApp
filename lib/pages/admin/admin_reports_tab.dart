import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/admin_models/report.dart';
import '../../models/user.dart';
import '../../provider/bottom_nav_provider.dart';
import '../../services/product_service.dart';
import '../../provider/admin_provider.dart';
import '../../provider/AuthProvider.dart';
import '../../utils/pagination.dart';
import '../productScreen.dart';

class _ReportCacheData {
  final bool isLoading;
  final UserModel? reporter;
  final String? targetLabel;

  _ReportCacheData({
    this.isLoading = false,
    this.reporter,
    this.targetLabel,
  });
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

  final Map<String, _ReportCacheData> _reportDataCache = {};

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

  Future<void> _loadReportData(Report report, bool isProductReport) async {
    if (_reportDataCache.containsKey(report.firestoreDocId)) return;
    setState(() {
      _reportDataCache[report.firestoreDocId] = _ReportCacheData(isLoading: true);
    });

    final auth = context.read<AuthProvider>();

    try {
      final reporter = await auth.getUserById(report.reporterId);

      String? targetLabel;
      if (isProductReport && report.productId != null) {
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(report.productId!)
            .get();
        final productName = productDoc.data()?['name'] as String?;
        targetLabel = productName != null
            ? 'На товар "$productName"'
            : 'На товар #${report.productId}';
      } else if (!isProductReport && report.targetUserId != null) {
        final targetUser = await auth.getUserById(report.targetUserId!);
        targetLabel = targetUser != null
            ? 'На пользователя ${targetUser.firstName} ${targetUser.lastName}'
            : 'На пользователя #${report.targetUserId}';
      } else {
        targetLabel = 'Неизвестно';
      }

      if (mounted) {
        setState(() {
          _reportDataCache[report.firestoreDocId] = _ReportCacheData(
            isLoading: false,
            reporter: reporter,
            targetLabel: targetLabel,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reportDataCache[report.firestoreDocId] = _ReportCacheData(
            isLoading: false,
            reporter: null,
            targetLabel: 'Ошибка загрузки',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AdminProvider>();
    final auth = context.read<AuthProvider>();
    final allItems = _filteredReports;
    final visibleItems = allItems.take(visibleCount).toList();
    final currentUserId = auth.currentUser?.uid;
    final theme = Theme.of(context);

    for (final report in visibleItems) {
      final isProductReport = report.targetType == ReportTargetType.product;
      if (!_reportDataCache.containsKey(report.firestoreDocId)) {
        _loadReportData(report, isProductReport);
      }
    }

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
                  hintText: 'Поиск жалоб',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 16),
                  prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    onPressed: () {
                      setState(() => _searchQuery = '');
                      resetPagination();
                    },
                  )
                      : null,
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
              _buildFilterChip(theme, 'Все', _filterTargetType == null, () {
                setState(() => _filterTargetType = null);
                resetPagination();
                _reportDataCache.clear();
              }),
              const SizedBox(width: 8),
              _buildFilterChip(theme, 'Товары', _filterTargetType == ReportTargetType.product, () {
                setState(() => _filterTargetType = ReportTargetType.product);
                resetPagination();
                _reportDataCache.clear();
              }),
              const SizedBox(width: 8),
              _buildFilterChip(theme, 'Пользователи', _filterTargetType == ReportTargetType.user, () {
                setState(() => _filterTargetType = ReportTargetType.user);
                resetPagination();
                _reportDataCache.clear();
              }),
            ],
          ),
        ),
        Expanded(
          child: visibleItems.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.report_off_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет жалоб',
                  style: TextStyle(
                    fontSize: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Жалобы на товары и пользователей будут отображаться здесь',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
              : ListView.builder(
            controller: scrollController,
            itemCount: visibleItems.length,
            itemBuilder: (context, index) {
              final report = visibleItems[index];
              final isProductReport = report.targetType == ReportTargetType.product;

              final cached = _reportDataCache[report.firestoreDocId];
              final isLoading = cached?.isLoading ?? true;
              final reporter = cached?.reporter;
              final reporterName = reporter != null
                  ? '${reporter.firstName} ${reporter.lastName}'
                  : null;
              final targetLabel = cached?.targetLabel ?? 'Загрузка...';
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
                        onTap: () => _navigateToTarget(context, report: report, isProductReport: isProductReport),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isProductReport ? theme.primaryColor.withOpacity(0.2) : theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Icon(
                                isProductReport ? Icons.shopping_bag : Icons.person,
                                color: theme.colorScheme.onSurface,
                                size: 24,
                              ),
                            ),
                            if (isUnread && !isLoading)
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
                              await context.read<AdminProvider>().markReportAsRead(report.firestoreDocId, currentUserId);
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
                                        isLoading
                                            ? 'Загрузка...'
                                            : (reporterName ?? 'Пользователь ${report.reporterId}'),
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
                                        isLoading ? 'Загрузка данных...' : targetLabel,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final dateFormat = (date.year == now.year) ? 'dd.MM' : 'dd.MM.yyyy';
    return DateFormat(dateFormat).format(date);
  }

  Future<void> _showReportDialog(BuildContext context, {
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

  void _navigateToTarget(BuildContext context, {required Report report, required bool isProductReport}) async {
    if (isProductReport && report.productId != null) {
      final product = await ProductService.getProductById(report.productId!);
      if (product != null && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen(product: product)));
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