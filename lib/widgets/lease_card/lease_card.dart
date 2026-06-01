import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activeLease.dart';
import '../../models/lease_request.dart';
import '../../pages/productScreen.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/LeaseRequestProvider.dart';
import '../../provider/activeLeasesProvider.dart';
import '../../services/connectivityService.dart';
import '../../services/product_service.dart';
import '../../utils/snackbar_custom.dart';
import 'lease_calendar.dart';

class LeaseCard extends StatefulWidget {
  final ActiveLease lease;
  const LeaseCard({required this.lease, super.key});

  @override
  State<LeaseCard> createState() => _LeaseCardState();
}


class _LeaseCardState extends State<LeaseCard> with SingleTickerProviderStateMixin {
  late Timer _timer;
  String _durationText = '';
  bool _showCalendar = false;
  bool? _directionMonth;
  DateTime _displayMonth = DateTime.now();
  late AnimationController _calendarAnimController;
  late Animation<double> _calendarAnimation;

  bool get _isHourly => widget.lease.isHourly;

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _updateDuration());
    _displayMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _calendarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _calendarAnimation = CurvedAnimation(
      parent: _calendarAnimController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _calendarAnimController.dispose();
    super.dispose();
  }

  void _toggleCalendar() {
    setState(() {
      _showCalendar = !_showCalendar;
      if (_showCalendar) {
        _calendarAnimController.forward();
      } else {
        _calendarAnimController.reverse();
      }
    });
  }

  void _updateDuration() {
    final lease = widget.lease;
    if (lease.startDate != null) {
      final now = DateTime.now();
      final diff = now.difference(lease.startDate!);
      final days = diff.inDays;
      final hours = diff.inHours % 24;

      if (_isHourly) {
        int totalHours = diff.inHours;
        if (diff.inMinutes % 60 > 0 || diff.inSeconds % 60 > 0) totalHours++;
        _durationText = '$totalHours ч.';
      } else {
        if (days > 0) {
          _durationText = '$days дн. $hours ч';
        } else if (hours > 0) {
          _durationText = '$hours ч.';
        } else {
          _durationText = 'менее часа';
        }
      }
    } else {
      _durationText = '';
    }
    if (mounted) setState(() {});
  }

  void _cancelPendingLease() {
    final lease = widget.lease;
    if (lease.status != LeaseStatus.pending) return;
    context.read<ActiveLeasesProvider>().removePendingLeaseByProductId(lease.productId);
    final requestProvider = context.read<LeaseRequestProvider>();

    if (lease.requestId != null) {
      requestProvider.rejectRequest(
        lease.requestId!,
        leasesProvider: context.read<ActiveLeasesProvider>(),
      );
    } else {
      final requests = requestProvider.requests;
      final relatedRequest = requests.cast<LeaseRequest?>().firstWhere(
            (r) => r!.productId == lease.productId && r.status == RequestStatus.pending,
        orElse: () => null,
      );
      if (relatedRequest != null) {
        requestProvider.rejectRequest(
          relatedRequest.firestoreDocId,
          leasesProvider: context.read<ActiveLeasesProvider>(),
        );
      }
    }
    SnackBarCustom.show(context, message: 'Запрос отменён');
  }

  void _completeLease() {
    final leasesProvider = context.read<ActiveLeasesProvider>();
    final leaseRequestProvider = context.read<LeaseRequestProvider>();
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    leasesProvider.requestCompleteLease(widget.lease.productId);
    leaseRequestProvider.requestCompleteLease(
      widget.lease,
      userId: user.uid,
      requesterRating: user.rating,
      leasesProvider: leasesProvider,
    );
    SnackBarCustom.show(context, message: 'Запрос на завершение отправлен владельцу');
  }

  String _priceUnit() {
    return _isHourly ? '₽/час' : '₽/день';
  }

  Future<void> _openProduct() async {
    try {
      final product = await ProductService.getProductById(widget.lease.productId);
      if (product != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final lease = widget.lease;
    final bool isPending = lease.status == LeaseStatus.pending;
    final bool isActive = lease.status == LeaseStatus.active && !lease.isCompleted;
    final connectivity = context.read<ConnectivityService>();
    final theme = Theme.of(context);

    return InkWell(
      onTap: _openProduct,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lease.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 25,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.amber
                        : (isActive
                        ? theme.primaryColor.withOpacity(0.2)
                        : theme.primaryColor.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    isPending ? 'Ожидание' : (isActive ? 'В аренде' : 'На проверке'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isPending)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _showCalendar ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleCalendar,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurface),
                            const SizedBox(width: 6),
                            Text(
                              _durationText.isNotEmpty
                                  ? _durationText
                                  : (_isHourly ? '${lease.currentDay} ч.' : '${lease.currentDay} дн.'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${lease.pricePerDay} ${_priceUnit()}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                secondChild: Row(
                  children: [
                    Text(
                      '${lease.pricePerDay} ${_priceUnit()}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${lease.pricePerDay} ${_priceUnit()}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showCalendar
                  ? SizeTransition(
                sizeFactor: _calendarAnimation,
                axisAlignment: -1.0,
                child: LeaseCalendar(
                  startDate: widget.lease.startDate!,
                  displayMonth: _displayMonth,
                  canGoPrevious: _canGoPreviousMonth(),
                  canGoNext: _canGoNextMonth(),
                  onPreviousMonth: _previousMonth,
                  onNextMonth: _nextMonth,
                  nextMonth: _directionMonth,
                  onClose: _toggleCalendar,
                ),
              )
                  : const SizedBox.shrink(),
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cancelPendingLease,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Отменить запрос'),
                ),
              ),
            ],
            if (lease.isPendingCompletion) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Ожидание подтверждения',
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final leaseRequestProvider = context.read<LeaseRequestProvider>();
                    final leasesProvider = context.read<ActiveLeasesProvider>();
                    LeaseRequest? completionRequest;
                    for (final r in leaseRequestProvider.requests) {
                      if (r.productId == lease.productId && r.type == RequestType.completion && r.status == RequestStatus.pending) {
                        completionRequest = r;
                        break;
                      }
                    }
                    if (completionRequest != null) {
                      final docRef = FirebaseFirestore.instance.collection("lease_requests").doc(completionRequest.firestoreDocId);
                      await docRef.update({
                        'type': RequestType.lease.index,
                        'status': RequestStatus.accepted.index,
                      });
                      completionRequest.type = RequestType.lease;
                      completionRequest.status = RequestStatus.accepted;
                      leaseRequestProvider.notifyListeners();
                      await leasesProvider.cancelCompletionRequest(lease.productId);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Отменить запрос на завершение'),
                ),
              ),
            ],
            if (isActive && !(context.read<AuthProvider>().currentUser?.blocked ?? false)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (!connectivity.hasInternet) {
                      SnackBarCustom.show(
                        context,
                        message: 'Нет интернета. Действие будет выполнено при подключении.',
                        actionLabel: 'Повторить',
                        onAction: () => _completeLease(),
                      );
                      return;
                    }
                    _completeLease();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('Завершить аренду'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canGoPreviousMonth() {
    final start = widget.lease.startDate;
    if (start == null) return false;
    final firstDayOfPrev = DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
    final lastDayOfPrev = DateTime(_displayMonth.year, _displayMonth.month, 0);
    final today = DateTime.now();
    return lastDayOfPrev.isAfter(start.subtract(const Duration(days: 1))) &&
        firstDayOfPrev.isBefore(today);
  }

  bool _canGoNextMonth() {
    final start = widget.lease.startDate;
    if (start == null) return false;
    final today = DateTime.now();
    final firstDayOfNext = DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
    return firstDayOfNext.isBefore(today) &&
        firstDayOfNext.isAfter(start.subtract(const Duration(days: 1)));
  }

  void _previousMonth() {
    if (_canGoPreviousMonth()) {
      setState(() {
        _directionMonth = false;
        _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
      });
    }
  }

  void _nextMonth() {
    if (_canGoNextMonth()) {
      setState(() {
        _directionMonth = true;
        _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
      });
    }
  }
}