class Order {
  final int? id;
  final int? userId;
  final String? customerName;
  final double? total;
  final String? status;
  final String? address;
  final String? paymentMethod;
  final String? createdAt;

  Order({
    this.id,
    this.userId,
    this.customerName,
    this.total,
    this.status,
    this.address,
    this.paymentMethod,
    this.createdAt,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      userId: map['user_id'],
      customerName: map['customer_name'],
      total: map['total'],
      status: map['status'],
      address: map['address'],
      paymentMethod: map['payment_method'],
      createdAt: map['created_at'],
    );
  }
}