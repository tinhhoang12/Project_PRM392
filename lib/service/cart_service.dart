
import '../entity/cart_item.dart';
import '../service/database_service.dart';
import '../service/notification_service.dart';

class CartService {
  CartService._();
  static final CartService instance = CartService._();
  final db = DatabaseService.instance;

  Future<void> add(int productId, double price, {int quantity = 1, int? userId}) async {
    final database = await db.database;

    final existing = await database.query(
      'cart',
      where: 'product_id = ?',
      whereArgs: [productId],
    );

    if (existing.isNotEmpty) {
      int oldQuantity = existing.first['quantity'] as int;
      await database.update(
        'cart',
        {'quantity': oldQuantity + quantity},
        where: 'product_id = ?',
        whereArgs: [productId],
      );
    } else {
      await database.insert('cart', {
        'product_id': productId,
        'quantity': quantity,
        'price': price,
      });
    }

    // Gửi thông báo khi thêm vào giỏ hàng
    if (userId != null) {
      await NotificationService.instance.addNotification(
        title: 'Đã thêm vào giỏ hàng',
        body: 'Bạn vừa thêm một sản phẩm vào giỏ hàng.',
        userId: userId,
        createdAt: DateTime.now().toString(),
      );
    }
  }

  Future<List<CartItem>> getAll() async {
    final database = await db.database;
    final result = await database.query('cart');

    return result.map((e) => CartItem.fromMap(e)).toList();
  }

  Future<void> increase(int productId) async {
    final database = await db.database;
    await database.rawUpdate(
      'UPDATE cart SET quantity = quantity + 1 WHERE product_id = ?',
      [productId],
    );
  }

  Future<void> decrease(int productId) async {
    final database = await db.database;
    await database.rawUpdate(
      'UPDATE cart SET quantity = quantity - 1 WHERE product_id = ? AND quantity > 1',
      [productId],
    );
  }

  Future<void> delete(int productId) async {
    final database = await db.database;
    await database.delete('cart',
        where: 'product_id = ?', whereArgs: [productId]);
  }

  Future<void> clear() async {
    final database = await db.database;
    await database.delete('cart');
  }
}