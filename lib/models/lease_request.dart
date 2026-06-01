enum RequestStatus { pending, accepted, rejected }
enum RequestType { lease, completion }

class LeaseRequest {
  final String firestoreDocId;
  final String productId;
  final String productName;
  final int pricePerDay;
  final int totalDays;
  final String requesterId;
  final String requesterFirstName;
  final String requesterLastName;
  final String? requesterAvatarPath;
  final String ownerId;
  final List<String> images;
  RequestStatus status;
  RequestType type;
  final bool isHourly;
  final bool notificationSent;
  final double requesterRating;

  LeaseRequest({
    required this.firestoreDocId,
    required this.productId,
    required this.productName,
    required this.pricePerDay,
    required this.totalDays,
    required this.requesterId,
    required this.requesterFirstName,
    required this.requesterLastName,
    this.requesterAvatarPath,
    required this.ownerId,
    this.images = const [],
    this.status = RequestStatus.pending,
    this.type = RequestType.lease,
    required this.isHourly,
    this.notificationSent = false,
    required this.requesterRating,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'pricePerDay': pricePerDay,
    'totalDays': totalDays,
    'requesterId': requesterId,
    'requesterFirstName': requesterFirstName,
    'requesterLastName': requesterLastName,
    'requesterAvatarPath': requesterAvatarPath,
    'ownerId': ownerId,
    'images': images,
    'status': status.index,
    'type': type.index,
    'isHourly': isHourly,
    'notificationSent': notificationSent,
    'requesterRating': requesterRating,
  };

  factory LeaseRequest.fromJson(Map<String, dynamic> json, {String? docId}) => LeaseRequest(
    firestoreDocId: docId ?? '',
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    pricePerDay: json['pricePerDay'] as int,
    totalDays: json['totalDays'] as int,
    requesterId: json['requesterId'] as String,
    requesterFirstName: json['requesterFirstName'] as String? ?? '',
    requesterLastName: json['requesterLastName'] as String? ?? '',
    requesterAvatarPath: json['requesterAvatarPath'] as String?,
    ownerId: json['ownerId'] as String,
    images: json['images'] != null ? List<String>.from(json['images']) : [],
    status: RequestStatus.values[json['status'] as int],
    type: RequestType.values[json['type'] as int],
    isHourly: json['isHourly'] as bool? ?? false,
    notificationSent: json['notificationSent'] as bool? ?? false,
    requesterRating: (json['requesterRating'] as num?)?.toDouble() ?? 5.0,
  );
}