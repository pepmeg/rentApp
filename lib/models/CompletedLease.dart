class CompletedLease {
  final String id;
  final String productId;
  final String productName;
  final int pricePerDay;
  final DateTime startDate;
  final DateTime endDate;
  final int units;
  final int extraHours;
  final bool isHourly;
  final int totalPrice;
  final String ownerId;
  final String ownerName;
  final String? ownerAvatarUrl;
  final List<String> images;

  CompletedLease({
    required this.id,
    required this.productId,
    required this.productName,
    required this.pricePerDay,
    required this.startDate,
    required this.endDate,
    required this.units,
    required this.extraHours,
    required this.isHourly,
    required this.totalPrice,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatarUrl,
    required this.images,
  });

  factory CompletedLease.fromJson(Map<String, dynamic> json, String docId) {
    final oldDays = json['days'] as int? ?? 0;
    final units = json['units'] as int? ?? oldDays;
    return CompletedLease(
      id: docId,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      pricePerDay: json['pricePerDay'] as int,
      startDate: DateTime.parse(json['startDate']).toUtc(),
      endDate: DateTime.parse(json['endDate']).toUtc(),
      units: units,
      extraHours: json['extraHours'] as int? ?? 0,
      isHourly: json['isHourly'] as bool? ?? false,
      totalPrice: json['totalPrice'] as int,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] ?? '',
      ownerAvatarUrl: json['ownerAvatarUrl'] as String?,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
    );
  }
}