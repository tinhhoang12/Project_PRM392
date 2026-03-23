import '../entity/product.dart';
import 'database_service.dart';

class ProductService {
  final dbService = DatabaseService.instance;

  Future<List<Product>> getAllProducts() async {
    final db = await dbService.database;
    final result = await db.query('products', orderBy: 'id DESC');

    return result.map((e) => Product.fromMap(e)).toList();
  }
Future<int> insertProduct(Map<String, dynamic> data) async {
  final db = await DatabaseService.instance.database;
  return db.insert('products', data);
}
Future<void> updateProduct(int id, Map<String, dynamic> data) async {
  final db = await DatabaseService.instance.database;

  await db.update(
    'products',
    data,
    where: 'id = ?',
    whereArgs: [id],
  );
}
Future<void> deleteProduct(int id) async {
  final db = await DatabaseService.instance.database;

  await db.delete(
    'products',
    where: 'id = ?',
    whereArgs: [id],
  );
}
Future<Product> getById(int id) async {
  final db = await DatabaseService.instance.database;

  final result = await db.query(
    'products',
    where: 'id = ?',
    whereArgs: [id],
  );

  if (result.isEmpty) {
    throw Exception("Product not found");
  }

  return Product.fromMap(result.first);
}

Future<List<Product>> getLowStockProducts({int threshold = 5}) async {
  final db = await DatabaseService.instance.database;
  final result = await db.query(
    'products',
    where: 'quantity <= ?',
    whereArgs: [threshold],
    orderBy: 'quantity ASC, id DESC',
  );
  return result.map((e) => Product.fromMap(e)).toList();
}
}
