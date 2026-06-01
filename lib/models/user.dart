class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String address;
  final String? avatarUrl;
  final String role;
  final bool blocked;
  final int unpaidLeaseCount;
  final DateTime? blockedUntil;
  final double rating;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber = '',
    this.address = '',
    this.avatarUrl,
    this.role = 'user',
    this.blocked = false,
    this.unpaidLeaseCount = 0,
    this.blockedUntil,
    this.rating = 5.0,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phoneNumber': phoneNumber,
    'address': address,
    'avatarUrl': avatarUrl,
    'role': role,
    'blocked': blocked,
    'unpaidLeaseCount': unpaidLeaseCount,
    'blockedUntil': blockedUntil?.toIso8601String(),
    'rating': rating,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid'] as String? ?? '',
    email: json['email'] as String? ?? '',
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    phoneNumber: json['phoneNumber'] as String? ?? '',
    address: json['address'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String?,
    role: json['role'] as String? ?? 'user',
    blocked: json['blocked'] as bool? ?? false,
    unpaidLeaseCount: json['unpaidLeaseCount'] as int? ?? 0,
    blockedUntil: json['blockedUntil'] != null
        ? DateTime.parse(json['blockedUntil']).toUtc()
        : null,
    rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
  );
}