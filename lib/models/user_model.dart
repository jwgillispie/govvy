class UserModel {
  final String uid;
  final String email;
  final String name;
  final String address;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.address,
    this.phone,
    this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'],
      createdAt: data['created_at']?.toDate(),
      lastLogin: data['last_login']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'address': address,
      'phone': phone,
      'created_at': createdAt,
      'last_login': lastLogin,
    };
  }
}