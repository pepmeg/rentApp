enum RequestStatus { pending, accepted, rejected }

class LeaseRequest {
  final int id;
  final int productId;
  final String productName;
  final int pricePerDay;
  final int totalDays;
  final int requesterId;
  final String requesterFirstName;
  final String requesterLastName;
  final String? requesterAvatarPath;
  final int ownerId;
  final List<String> images;
  RequestStatus status;

  LeaseRequest({
    required this.id,
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
  });

  Map<String, dynamic> toJson() => {
    'id': id,
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
  };

  factory LeaseRequest.fromJson(Map<String, dynamic> json) => LeaseRequest(
    id: json['id'] as int,
    productId: json['productId'] as int,
    productName: json['productName'] as String,
    pricePerDay: json['pricePerDay'] as int,
    totalDays: json['totalDays'] as int,
    requesterId: json['requesterId'] as int,
    requesterFirstName: json['requesterFirstName'] as String,
    requesterLastName: json['requesterLastName'] as String,
    requesterAvatarPath: json['requesterAvatarPath'] as String?,
    ownerId: json['ownerId'] as int,
    images: List<String>.from(json['images'] as List),
    status: RequestStatus.values[json['status'] as int],
  );
}