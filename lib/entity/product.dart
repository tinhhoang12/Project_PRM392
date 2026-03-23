class Product {
  final int? id;
  final String name;
  final int categoryId;
  final double price;
  final int quantity;
  final String image;
  final String? description;

  Product({
    this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    this.quantity = 0,
    required this.image,
    this.description,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      categoryId: map['category_id'] as int,
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      image: map['image'] as String,
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'price': price,
      'quantity': quantity,
      'image': image,
      'description': description,
    };
  }
}
