enum LeaseStatus { active, pending, pendingCompletion }

class ActiveLease {
  final int productId;
  final String name;
  final int pricePerDay;
  final DateTime? startDate;
  final int totalDays;
  LeaseStatus status;
  final double progress;
  final int userId;
  final int ownerId;
  final String userFirstName;
  final String userLastName;
  final String? userAvatarPath;
  bool isCompleted;

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
    this.userAvatarPath,
    this.status = LeaseStatus.pending,
    this.isCompleted = false,
  }) : progress = (status == LeaseStatus.active || status == LeaseStatus.pendingCompletion)
      ? calculateProgress(startDate!, totalDays)
      : 0.0;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'pricePerDay': pricePerDay,
    'startDate': startDate?.toIso8601String(),
    'totalDays': totalDays,
    'userId': userId,
    'ownerId': ownerId,
    'userFirstName': userFirstName,
    'userLastName': userLastName,
    'userAvatarPath': userAvatarPath,
    'status': status.index,
    'isCompleted': isCompleted,
  };

  factory ActiveLease.fromJson(Map<String, dynamic> json) => ActiveLease(
    productId: json['productId'] as int,
    name: json['name'] as String,
    pricePerDay: json['pricePerDay'] as int,
    startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
    totalDays: json['totalDays'] as int,
    userId: json['userId'] as int,
    ownerId: json['ownerId'] as int? ?? 0,
    userFirstName: json['userFirstName'] as String? ?? '',
    userLastName: json['userLastName'] as String? ?? '',
    userAvatarPath: json['userAvatarPath'] as String?,
    status: json['status'] != null
        ? LeaseStatus.values[json['status'] as int]
        : LeaseStatus.pending,
    isCompleted: json['isCompleted'] as bool? ?? false,
  );

  bool get isPending => status == LeaseStatus.pending;
  bool get isActive => status == LeaseStatus.active && !isCompleted;
  bool get isPendingCompletion => status == LeaseStatus.pendingCompletion;

  int get remainingDays {
    if (status == LeaseStatus.pending || startDate == null) return totalDays;
    final endDate = startDate!.add(Duration(days: totalDays));
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  int get currentDay {
    if (startDate == null) return 1;
    final diff = DateTime.now().difference(startDate!).inDays;
    return diff + 1;
  }

  static double calculateProgress(DateTime start, int totalDays) {
    final now = DateTime.now();
    if (now.isBefore(start)) return 0.0;
    final passed = now.difference(start).inDays;
    return (passed / totalDays).clamp(0.0, 1.0);
  }
}