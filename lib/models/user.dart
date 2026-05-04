class UserModel {
  final int id;
  final String role;
  final bool blocked;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String address;
  final String phoneNumber;
  final String? avatarPath;

  UserModel({
    required this.id,
    this.role = 'user',
    this.blocked = false,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.phoneNumber,
    this.avatarPath,
  });

  Map<String, dynamic> toJson() =>
      {
        'id': id,
        'role': role,
        'blocked': blocked,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'address': address,
        'phoneNumber': phoneNumber,
        if (avatarPath != null) 'avatarPath': avatarPath,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      avatarPath: json['avatarPath'] as String?,
      role: json['role'] as String? ?? 'user',
      blocked: json['blocked'] as bool? ?? false,
    );
  }
}