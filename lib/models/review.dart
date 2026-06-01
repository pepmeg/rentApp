class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String userAvatarPath;
  final DateTime createdAt;
  final int rating;
  final String text;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userAvatarPath = '',
    required this.createdAt,
    required this.rating,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'userId': userId,
    'userName': userName,
    'userAvatarPath': userAvatarPath,
    'createdAt': createdAt.toIso8601String(),
    'rating': rating,
    'text': text,
  };

  factory Review.fromJson(Map<String, dynamic> json, {required String docId}) => Review(
    id: docId,
    productId: json['productId'] as String,
    userId: json['userId'] as String,
    userName: json['userName'] as String,
    userAvatarPath: json['userAvatarPath'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    rating: json['rating'] as int,
    text: json['text'] as String,
  );
}