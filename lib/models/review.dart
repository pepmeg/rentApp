class Review {
  final int id;
  final int productId;
  final int userId;
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
    'id': id,
    'productId': productId,
    'userId': userId,
    'userName': userName,
    'userAvatarPath': userAvatarPath,
    'createdAt': createdAt.toIso8601String(),
    'rating': rating,
    'text': text,
  };

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'],
    productId: json['productId'],
    userId: json['userId'],
    userName: json['userName'],
    userAvatarPath: json['userAvatarPath'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
    rating: json['rating'],
    text: json['text'],
  );
}