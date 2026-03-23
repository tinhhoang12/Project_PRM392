class Address {
  final int id;
  final int userId;
  final String name;
  final String phone;
  final String address;
  final int isDefault;

  Address({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.address,
    required this.isDefault,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      isDefault: map['is_default'],
    );
  }
}