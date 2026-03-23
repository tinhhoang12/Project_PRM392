class CartItem {
  final int? id;
  final int userId;
  final int productId;
  final int quantity;
  final double price;

  CartItem({
    this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.price,
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
    };
  }
}
