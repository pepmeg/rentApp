enum LeaseStatus { active, pending }

class ActiveLease {
  final int productId;
  final String name;
  final int pricePerDay;
  final DateTime? startDate;
  final int totalDays;
  final LeaseStatus status;
  final double progress;

  ActiveLease({
    required this.productId,
    required this.name,
    required this.pricePerDay,
    this.startDate,
    required this.totalDays,
    this.status = LeaseStatus.pending,
  }) : progress = status == LeaseStatus.active
      ? calculateProgress(startDate!, totalDays)
      : 0.0;

  int get remainingDays {
    if (status == LeaseStatus.pending || startDate == null) return totalDays;
    final endDate = startDate!.add(Duration(days: totalDays));
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  static double calculateProgress(DateTime start, int totalDays) {
    final now = DateTime.now();
    if (now.isBefore(start)) return 0.0;
    final passed = now.difference(start).inDays;
    return (passed / totalDays).clamp(0.0, 1.0);
  }
}