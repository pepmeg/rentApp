import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/product_data.dart';
import '../../models/activeLease.dart';
import '../../models/lease_request.dart';
import '../../pages/productScreen.dart';
import '../../provider/AuthProvider.dart';
import '../../provider/LeaseRequestProvider.dart';
import '../../provider/activeLeasesProvider.dart';
import '../../utils/colors.dart';
import '../../utils/snackbar_custom.dart';
import 'lease_calendar.dart';

class LeaseCard extends StatefulWidget {
  final ActiveLease lease;
  const LeaseCard({required this.lease, super.key});

  @override
  State<LeaseCard> createState() => _LeaseCardState();
}

class _LeaseCardState extends State<LeaseCard>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  String _durationText = '';
  bool _showCalendar = false;
  bool? _directionMonth;
  DateTime _displayMonth = DateTime.now();
  late AnimationController _calendarAnimController;
  late Animation<double> _calendarAnimation;

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer =
        Timer.periodic(const Duration(seconds: 60), (_) => _updateDuration());
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
      final product = ProductData.getProductById(lease.productId);
      final isHourly = product?.isPricePerHour ?? false;

      if (isHourly) {
        final totalHours = diff.inHours;
        _durationText = totalHours > 0 ? '$totalHours ч.' : 'менее часа';
      } else {
        if (days > 0) {
          _durationText = '$days дн. ${hours}ч';
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
    context
        .read<ActiveLeasesProvider>()
        .removePendingLeaseByProductId(lease.productId);
    final requestProvider = context.read<LeaseRequestProvider>();
    final requests = requestProvider.requests;
    final relatedRequest = requests.cast<LeaseRequest?>().firstWhere(
          (r) =>
      r!.productId == lease.productId &&
          r.status == RequestStatus.pending,
      orElse: () => null,
    );
    if (relatedRequest != null) {
      requestProvider.rejectRequest(relatedRequest.id);
    }
    SnackBarCustom.show(context, message: 'Запрос отменён');
  }

  String _priceUnit() {
    final product = ProductData.getProductById(widget.lease.productId);
    final bool isHourly = product?.isPricePerHour ?? false;
    return isHourly ? '₽/час' : '₽/день';
  }

  @override
  Widget build(BuildContext context) {
    final lease = widget.lease;
    final bool isPending = lease.status == LeaseStatus.pending;
    final bool isActive =
        lease.status == LeaseStatus.active && !lease.isCompleted;

    final product = ProductData.getProductById(lease.productId);
    final bool isHourly = product?.isPricePerHour ?? false;

    return InkWell(
      onTap: _showCalendar
          ? null
          : () {
        if (product != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProductScreen(product: product)));
        } else {
          SnackBarCustom.show(context, message: 'Товар не найден');
        }
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.whiteAntique,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и статус
            Row(
              children: [
                Expanded(
                  child: Text(lease.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.oliveGray)),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 25,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isPending
                        ? AppColors.yellowSchoolBus
                        : (isActive
                        ? AppColors.lightGreen
                        : AppColors.copper.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    isPending
                        ? 'Ожидание'
                        : (isActive ? 'В аренде' : 'На проверке'),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.oliveGray),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Анимированная строка: время ↔ цена
            if (!isPending)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _showCalendar
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleCalendar,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.spaceCream,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: AppColors.oliveGray),
                            const SizedBox(width: 6),
                            Text(
                              _durationText.isNotEmpty
                                  ? _durationText
                                  : (isHourly
                                  ? '${lease.currentDay} ч.'
                                  : '${lease.currentDay} дн.'),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.oliveGray),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${lease.pricePerDay} ${_priceUnit()}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.oliveGray),
                    ),
                  ],
                ),
                secondChild: Row(
                  children: [
                    Text(
                      '${lease.pricePerDay} ${_priceUnit()}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.oliveGray),
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
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.oliveGray),
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
                    foregroundColor: AppColors.oliveGray,
                    side: BorderSide(
                        color: AppColors.oliveGray.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
                  color: AppColors.copper.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Ожидание подтверждения',
                    style: TextStyle(color: AppColors.copper)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final leaseRequestProvider =
                    context.read<LeaseRequestProvider>();
                    final leasesProvider =
                    context.read<ActiveLeasesProvider>();
                    final requests = leaseRequestProvider.requests;
                    final completionRequest =
                    requests.cast<LeaseRequest?>().firstWhere(
                          (r) =>
                      r!.productId == lease.productId &&
                          r.type == RequestType.completion &&
                          r.status == RequestStatus.pending,
                      orElse: () => null,
                    );
                    if (completionRequest != null) {
                      leaseRequestProvider.rejectCompletion(
                          completionRequest.id, leasesProvider);
                      SnackBarCustom.show(context,
                          message: 'Запрос на завершение отменён');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.oliveGray,
                    side: BorderSide(
                        color: AppColors.oliveGray.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Отменить запрос на завершение'),
                ),
              ),
            ],
            if (isActive) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final leasesProvider =
                    context.read<ActiveLeasesProvider>();
                    final leaseRequestProvider =
                    context.read<LeaseRequestProvider>();
                    final user =
                        context.read<AuthProvider>().currentUser;
                    if (user == null) return;
                    leasesProvider
                        .requestCompleteLease(lease.productId);
                    leaseRequestProvider.addRequest(LeaseRequest(
                      id: DateTime.now().millisecondsSinceEpoch,
                      productId: lease.productId,
                      productName: lease.name,
                      pricePerDay: lease.pricePerDay,
                      totalDays: lease.totalDays,
                      requesterId: user.id,
                      requesterFirstName: user.firstName,
                      requesterLastName: user.lastName,
                      requesterAvatarPath: user.avatarPath,
                      ownerId: lease.ownerId,
                      type: RequestType.completion,
                    ));
                    SnackBarCustom.show(context,
                        message:
                        'Запрос на завершение отправлен владельцу');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.copper,
                    foregroundColor: AppColors.whiteAntique,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
    final firstDayOfPrev =
    DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
    final lastDayOfPrev =
    DateTime(_displayMonth.year, _displayMonth.month, 0);
    final today = DateTime.now();
    return lastDayOfPrev
        .isAfter(start.subtract(const Duration(days: 1))) &&
        firstDayOfPrev.isBefore(today);
  }

  bool _canGoNextMonth() {
    final start = widget.lease.startDate;
    if (start == null) return false;
    final today = DateTime.now();
    final firstDayOfNext =
    DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
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