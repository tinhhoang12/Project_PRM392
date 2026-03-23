import '../entity/cart_item.dart';
import 'package:sqflite/sqflite.dart';
import '../service/auth_service.dart';
import '../service/database_service.dart';
import '../service/notification_service.dart';

class CartService {
  CartService._();
  static final CartService instance = CartService._();
  final db = DatabaseService.instance;
  final _authService = AuthService();

  Future<int?> _resolveUserId(int? userId) async {
    return userId ?? await _authService.getCurrentUserId();
  }

  Future<int> _getProductStock(Database database, int productId) async {
    final product = await database.query(
      'products',
      columns: ['quantity'],
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (product.isEmpty) {
      throw Exception('Product not found');
    }
    return (product.first['quantity'] as num?)?.toInt() ?? 0;
  }

  Future<void> add(
    int productId,
    double price, {
    int quantity = 1,
    int? userId,
  }) async {
    final database = await db.database;
    final resolvedUserId = await _resolveUserId(userId);
    if (resolvedUserId == null) {
      throw Exception('User must be logged in to add cart item');
    }

    if (quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }

    final stock = await _getProductStock(database, productId);
    final existing = await database.query(
      'cart',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [resolvedUserId, productId],
      limit: 1,
    );

    final currentQty = existing.isNotEmpty
        ? ((existing.first['quantity'] as num?)?.toInt() ?? 0)
        : 0;
    final nextQty = currentQty + quantity;
    if (nextQty > stock) {
      throw Exception('Not enough stock. Available: $stock');
    }

    if (existing.isNotEmpty) {
      await database.update(
        'cart',
        {
          'quantity': nextQty,
          'price': price,
        },
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [resolvedUserId, productId],
      );
    } else {
      await database.insert('cart', {
        'user_id': resolvedUserId,
        'product_id': productId,
        'quantity': quantity,
        'price': price,
      });
    }

    await NotificationService.instance.addNotification(
      title: 'Da them vao gio hang',
      body: 'Ban vua them mot san pham vao gio hang.',
      userId: resolvedUserId,
      createdAt: DateTime.now().toString(),
    );
  }

  Future<List<CartItem>> getAll({int? userId}) async {
    final database = await db.database;
    final resolvedUserId = await _resolveUserId(userId);
    if (resolvedUserId == null) return [];

    final result = await database.query(
      'cart',
      where: 'user_id = ?',
      whereArgs: [resolvedUserId],
      orderBy: 'id DESC',
    );

    return result.map((e) => CartItem.fromMap(e)).toList();
  }

  Future<void> increase(int productId, {int? userId}) async {
    final database = await db.database;
    final resolvedUserId = await _resolveUserId(userId);
    if (resolvedUserId == null) return;

    final item = await database.query(
      'cart',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [resolvedUserId, productId],
      limit: 1,
    );
    if (item.isEmpty) return;

    final currentQty = (item.first['quantity'] as num?)?.toInt() ?? 0;
    final stock = await _getProductStock(database, productId);
    if (currentQty >= stock) {
      throw Exception('Cannot increase. Only $stock item(s) left in stock.');
    }

    await database.rawUpdate(
      'UPDATE cart SET quantity = quantity + 1 WHERE user_id = ? AND product_id = ?',
      [resolvedUserId, productId],
    );
  }

  Future<void> decrease(int productId, {int? userId}) async {
    final database = await db.database;
    final resolvedUserId = await _resolveUserId(userId);
    if (resolvedUserId == null) return;

    await database.rawUpdate(
      'UPDATE cart SET quantity = quantity - 1 WHERE user_id = ? AND product_id = ? AND quantity > 1',
      [resolvedUserId, productId],
    );
  }

  Future<void> delete(int productId, {int? userId}) async {
    final database = await db.database;
    final resolvedUserId = await _resolveUserId(userId);
    if (resolvedUserId == null) return;

    await database.delete(
      'cart',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [resolvedUserId, productId],
    );
  }

  Future<void> clear({int? userId}) async {
    final database = await db.database;
    final resolvedUserId = await _resolveUserId(userId);
    if (resolvedUserId == null) return;

    await database.delete(
      'cart',
      where: 'user_id = ?',
      whereArgs: [resolvedUserId],
    );
  }
}
