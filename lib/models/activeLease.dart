enum LeaseStatus { active, pending, pendingCompletion }

class ActiveLease {
  final String productId;
  final String name;
  final int pricePerDay;
  final DateTime? startDate;
  final int totalDays;
  LeaseStatus status;
  final String userId;
  final String ownerId;
  final String userFirstName;
  final String userLastName;
  final String? userAvatarUrl;
  bool isCompleted;
  final String? requestId;
  final bool isHourly;
  final double requesterRating;

  ActiveLease({
    required this.productId,
    required this.name,
    required this.pricePerDay,
    this.startDate,
    required this.totalDays,
    required this.userId,
    required this.ownerId,
    required this.userFirstName,
    required this.userLastName,
    this.userAvatarUrl,
    this.status = LeaseStatus.pending,
    this.isCompleted = false,
    this.requestId,
    required this.isHourly,
    required this.requesterRating,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'pricePerDay': pricePerDay,
    'startDate': startDate?.toUtc().toIso8601String(),
    'totalDays': totalDays,
    'userId': userId,
    'ownerId': ownerId,
    'userFirstName': userFirstName,
    'userLastName': userLastName,
    'userAvatarUrl': userAvatarUrl,
    'status': status.index,
    'isCompleted': isCompleted,
    'requestId': requestId,
    'isHourly': isHourly,
    'requesterRating': requesterRating,
  };

  factory ActiveLease.fromJson(Map<String, dynamic> json) => ActiveLease(
    productId: json['productId'] as String,
    name: json['name'] as String,
    pricePerDay: json['pricePerDay'] as int,
    startDate: json['startDate'] != null
        ? DateTime.parse(json['startDate']).toUtc()
        : null,
    totalDays: json['totalDays'] as int,
    userId: json['userId'] as String,
    ownerId: json['ownerId'] as String,
    userFirstName: json['userFirstName'] as String? ?? '',
    userLastName: json['userLastName'] as String? ?? '',
    userAvatarUrl: json['userAvatarUrl'] as String?,
    status: LeaseStatus.values[json['status'] as int],
    isCompleted: json['isCompleted'] as bool? ?? false,
    requestId: json['requestId'] as String?,
    isHourly: json['isHourly'] as bool? ?? false,
    requesterRating: (json['requesterRating'] as num?)?.toDouble() ?? 5.0,
  );

  bool get isPending => status == LeaseStatus.pending;
  bool get isActive => status == LeaseStatus.active && !isCompleted;
  bool get isPendingCompletion => status == LeaseStatus.pendingCompletion;

  int get remainingDays {
    if (status == LeaseStatus.pending || startDate == null) return totalDays;
    final endDate = startDate!.add(Duration(days: totalDays));
    final diff = endDate.difference(DateTime.now().toUtc()).inDays;
    return diff > 0 ? diff : 0;
  }

  int get currentDay {
    if (startDate == null) return 1;
    final diff = DateTime.now().toUtc().difference(startDate!).inDays;
    return diff + 1;
  }

  static double calculateProgress(DateTime start, int totalDays) {
    final now = DateTime.now().toUtc();
    if (now.isBefore(start)) return 0.0;
    final passed = now.difference(start).inDays;
    return (passed / totalDays).clamp(0.0, 1.0);
  }
}