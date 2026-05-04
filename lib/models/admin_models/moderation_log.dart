class ModerationLog {
  final int id;
  final int adminId;
  final int? productId;
  final int? targetUserId;
  final String action;
  final String? reason;
  final DateTime timestamp;

  ModerationLog({
    required this.id,
    required this.adminId,
    this.productId,
    this.targetUserId,
    required this.action,
    this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'adminId': adminId,
    'productId': productId,
    'targetUserId': targetUserId,
    'action': action,
    'reason': reason,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ModerationLog.fromJson(Map<String, dynamic> json) => ModerationLog(
    id: json['id'],
    adminId: json['adminId'],
    productId: json['productId'],
    targetUserId: json['targetUserId'],
    action: json['action'],
    reason: json['reason'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}