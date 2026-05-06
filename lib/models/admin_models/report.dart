enum ReportStatus { pending, reviewed, resolved }

enum ReportTargetType { product, user }

class Report {
  final int id;
  final int? productId;
  final int? targetUserId;
  final int reporterId;
  final String reason;
  final ReportStatus status;
  final DateTime createdAt;
  final ReportTargetType targetType;
  final Set<int> readByUserIds;

  Report({
    required this.id,
    this.productId,
    this.targetUserId,
    required this.reporterId,
    required this.reason,
    this.status = ReportStatus.pending,
    required this.createdAt,
    required this.targetType,
    Set<int>? readByUserIds,
  }) : readByUserIds = readByUserIds ?? {};

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'targetUserId': targetUserId,
    'reporterId': reporterId,
    'reason': reason,
    'status': status.index,
    'createdAt': createdAt.toIso8601String(),
    'targetType': targetType.index,
    'readByUserIds': readByUserIds.toList(),
  };

  factory Report.fromJson(Map<String, dynamic> json) {
    final targetTypeIndex = json['targetType'];
    final targetType = targetTypeIndex != null
        ? ReportTargetType.values[targetTypeIndex]
        : ReportTargetType.product;

    final rawList = json['readByUserIds'];
    final Set<int> readByUserIds = rawList != null
        ? Set<int>.from((rawList as List<dynamic>).cast<int>())
        : {};

    return Report(
      id: json['id'],
      productId: json['productId'],
      targetUserId: json['targetUserId'],
      reporterId: json['reporterId'],
      reason: json['reason'],
      status: ReportStatus.values[json['status']],
      createdAt: DateTime.parse(json['createdAt']),
      targetType: targetType,
      readByUserIds: readByUserIds,
    );
  }
}