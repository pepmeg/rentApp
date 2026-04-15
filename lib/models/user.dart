class UserModel {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String address;
  final String phoneNumber;

  UserModel({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() =>
      {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'address': address,
        'phoneNumber': phoneNumber,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
        email: json['email'] ?? '',
        password: json['password'] ?? '',
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        address: json['address'] ?? '',
        phoneNumber: json['phoneNumber'] ?? '',
    );
  }
}