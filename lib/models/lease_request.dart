enum RequestStatus { pending, accepted, rejected }

class LeaseRequest {
  final int id;
  final int productId;
  final String productName;
  final int pricePerDay;
  final int totalDays;
  final int requesterId;
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
    required this.ownerId,
    this.images = const [],
    this.status = RequestStatus.pending,
  });
}