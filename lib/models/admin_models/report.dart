enum ReportStatus { pending, reviewed, resolved }
enum ReportTargetType { product, user }

class Report {
  final String firestoreDocId;
  final int id;
  final String? productId;
  final String? targetUserId;
  final String reporterId;
  final String reason;
  final ReportStatus status;
  final DateTime createdAt;
  final ReportTargetType targetType;
  final Set<String> readByUserIds;

  Report({
    required this.firestoreDocId,
    required this.id,
    this.productId,
    this.targetUserId,
    required this.reporterId,
    required this.reason,
    this.status = ReportStatus.pending,
    required this.createdAt,
    required this.targetType,
    Set<String>? readByUserIds,
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

  factory Report.fromJson(Map<String, dynamic> json, {required String docId}) {
    final targetTypeIndex = json['targetType'];
    final targetType = targetTypeIndex != null
        ? ReportTargetType.values[targetTypeIndex]
        : ReportTargetType.product;

    final rawList = json['readByUserIds'];
    final Set<String> readByUserIds = rawList != null
        ? Set<String>.from((rawList as List<dynamic>).map((e) => e.toString()))
        : {};

    return Report(
      firestoreDocId: docId,
      id: json['id'],
      productId: json['productId'] as String?,
      targetUserId: json['targetUserId'] as String?,
      reporterId: json['reporterId'] as String,
      reason: json['reason'],
      status: ReportStatus.values[json['status']],
      createdAt: DateTime.parse(json['createdAt']),
      targetType: targetType,
      readByUserIds: readByUserIds,
    );
  }
}