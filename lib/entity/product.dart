import 'dart:io';

class Product {
  final int? id;
  final String name;
  final int categoryId;
  final double price;
  final String image; // có thể là URL hoặc local path
  final String? description;

  Product({
    this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.image,
    this.description,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      categoryId: map['category_id'],
      price: (map['price'] as num).toDouble(),
      image: map['image'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'price': price,
      'image': image,
      'description': description,
    };
  }
}