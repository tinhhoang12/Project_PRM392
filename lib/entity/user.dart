class User {
  final int? id;
  final String username;
  final String password;
  final String? email;
  final String? fullName;
  final String? phone;
  final String? address;
  final String? avatar;
  final String role;
  final String? createdAt;

  User({
    this.id,
    required this.username,
    required this.password,
    this.email,
    this.fullName,
    this.phone,
    this.address,
    this.avatar,
    this.role = 'user',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'address': address,
      'avatar': avatar,
      'role': role,
      'created_at': createdAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      email: map['email'],
      fullName: map['full_name'],
      phone: map['phone'],
      address: map['address'],
      avatar: map['avatar'],
      role: map['role'] ?? 'user',
      createdAt: map['created_at'],
    );
  }
}