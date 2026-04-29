import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/product_data.dart';
import '../models/activeLease.dart';
import '../models/lease_request.dart';
import '../pages/productScreen.dart';
import '../provider/AuthProvider.dart';
import '../provider/LeaseRequestProvider.dart';
import '../provider/activeLeasesProvider.dart';
import '../utils/colors.dart';
import '../utils/snackbar_custom.dart';

class LeaseCard extends StatefulWidget {
  final ActiveLease lease;
  const LeaseCard({required this.lease, super.key});

  @override
  State<LeaseCard> createState() => _LeaseCardState();
}

class _LeaseCardState extends State<LeaseCard> {
  late Timer _timer;
  String _durationText = '';

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _updateDuration());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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
        if (totalHours > 0) {
          _durationText = '$totalHours ч.';
        } else {
          _durationText = 'менее часа';
        }
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
    context.read<ActiveLeasesProvider>().removePendingLeaseByProductId(lease.productId);
    final requestProvider = context.read<LeaseRequestProvider>();
    final requests = requestProvider.requests;
    final relatedRequest = requests.cast<LeaseRequest?>().firstWhere(
          (r) => r!.productId == lease.productId && r.status == RequestStatus.pending,
      orElse: () => null,
    );
    if (relatedRequest != null) {
      requestProvider.rejectRequest(relatedRequest.id);
    }
    SnackBarCustom.show(context, message: 'Запрос отменён');
  }

  @override
  Widget build(BuildContext context) {
    final lease = widget.lease;
    final bool isPending = lease.status == LeaseStatus.pending;
    final bool isActive = lease.status == LeaseStatus.active && !lease.isCompleted;

    final product = ProductData.getProductById(lease.productId);
    final bool isHourly = product?.isPricePerHour ?? false;
    final String priceUnit = isHourly ? '₽/час' : '₽/день';
    final String totalUnit = isHourly ? 'Часов' : 'Дней';

    return InkWell(
      onTap: () {
        if (product != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
          );
        } else {
          SnackBarCustom.show(context, message: 'Товар не найден');
        }
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.whiteAntique,
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.oliveGray),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 25,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isPending
                        ? AppColors.yellowSchoolBus
                        : isActive
                        ? AppColors.lightGreen
                        : AppColors.copper.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    isPending ? 'Ожидание' : (isActive ? 'В аренде' : 'На проверке'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.oliveGray),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isPending)
                  Expanded(
                    child: Text(
                      'Времени с начала: ${_durationText.isNotEmpty ? _durationText : (isHourly ? '${lease.currentDay} ч.' : '${lease.currentDay} дн.')}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                    ),
                  ),
                if (isPending)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${lease.pricePerDay} $priceUnit',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                      ),
                    ),
                  )
                else
                  Text(
                    '${lease.pricePerDay} $priceUnit',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                  ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.oliveGray,
                    side: BorderSide(color: AppColors.oliveGray.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Отменить запрос', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  onPressed: _cancelPendingLease,
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
                child: Text(
                  'Ожидание подтверждения',
                  style: TextStyle(
                    color: AppColors.copper,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.oliveGray,
                    side: BorderSide(color: AppColors.oliveGray.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Отменить запрос на завершение', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  onPressed: () {
                    final leaseRequestProvider = context.read<LeaseRequestProvider>();
                    final leasesProvider = context.read<ActiveLeasesProvider>();
                    final requests = leaseRequestProvider.requests;
                    final completionRequest = requests.cast<LeaseRequest?>().firstWhere(
                          (r) => r!.productId == lease.productId && r.type == RequestType.completion && r.status == RequestStatus.pending,
                      orElse: () => null,
                    );
                    if (completionRequest != null) {
                      leaseRequestProvider.rejectCompletion(completionRequest.id, leasesProvider);
                      SnackBarCustom.show(context, message: 'Запрос на завершение отменён');
                    }
                  },
                ),
              ),
            ],
            if (isActive) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.copper,
                    foregroundColor: AppColors.whiteAntique,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('Завершить аренду', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  onPressed: () {
                    final leasesProvider = context.read<ActiveLeasesProvider>();
                    final leaseRequestProvider = context.read<LeaseRequestProvider>();
                    final user = context.read<AuthProvider>().currentUser;
                    if (user == null) return;
                    leasesProvider.requestCompleteLease(lease.productId);
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
                    SnackBarCustom.show(context, message: 'Запрос на завершение отправлен владельцу');
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}