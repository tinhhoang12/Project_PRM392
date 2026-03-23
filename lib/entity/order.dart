class Order {
  final int? id;
  final int? userId;
  final int? addressId;
  final String? receiverName;
  final String? receiverPhone;
  final String? receiverAddress;
  final double? total;
  final double? subtotal;
  final double? discountAmount;
  final double? shippingFee;
  final String? status;
  final String? paymentMethod;
  final String? paymentStatus;
  final int? userReceivedConfirmed;
  final String? createdAt;

  Order({
    this.id,
    this.userId,
    this.addressId,
    this.receiverName,
    this.receiverPhone,
    this.receiverAddress,
    this.total,
    this.subtotal,
    this.discountAmount,
    this.shippingFee,
    this.status,
    this.paymentMethod,
    this.paymentStatus,
    this.userReceivedConfirmed,
    this.createdAt,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      addressId: map['address_id'] as int?,
      receiverName: map['receiver_name'] as String?,
      receiverPhone: map['receiver_phone'] as String?,
      receiverAddress: map['receiver_address'] as String?,
      total: (map['total'] as num?)?.toDouble(),
      subtotal: (map['subtotal'] as num?)?.toDouble(),
      discountAmount: (map['discount_amount'] as num?)?.toDouble(),
      shippingFee: (map['shipping_fee'] as num?)?.toDouble(),
      status: map['status'] as String?,
      paymentMethod: map['payment_method'] as String?,
      paymentStatus: map['payment_status'] as String?,
      userReceivedConfirmed: map['user_received_confirmed'] as int?,
      createdAt: map['created_at'] as String?,
    );
  }
}
