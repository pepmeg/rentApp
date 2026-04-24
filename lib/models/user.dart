class UserModel {
  final int id;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String address;
  final String phoneNumber;
  final String? avatarPath;

  UserModel({
    required this.id,
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
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        password: json['password'] ?? '',
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        address: json['address'] ?? '',
        phoneNumber: json['phoneNumber'] ?? '',
        avatarPath: json['avatarPath'],
    );
  }
}