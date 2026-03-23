class CartItem {
  final int? id;
  final int productId;
  final int quantity;
  final double price;

  CartItem({
    this.id,
    required this.productId,
    required this.quantity,
    required this.price,
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      price: (map['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
    };
  }
}