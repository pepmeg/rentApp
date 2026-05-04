enum ReportStatus { pending, reviewed, resolved }

class Report {
  final int id;
  final int productId;
  final int reporterId;
  final String reason;
  final ReportStatus status;
  final DateTime createdAt;

  Report({
    required this.id,
    required this.productId,
    required this.reporterId,
    required this.reason,
    this.status = ReportStatus.pending,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'reporterId': reporterId,
    'reason': reason,
    'status': status.index,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Report.fromJson(Map<String, dynamic> json) => Report(
    id: json['id'],
    productId: json['productId'],
    reporterId: json['reporterId'],
    reason: json['reason'],
    status: ReportStatus.values[json['status']],
    createdAt: DateTime.parse(json['createdAt']),
  );
}