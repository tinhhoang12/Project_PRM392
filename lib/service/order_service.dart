
import '../entity/order.dart';
import '../service/database_service.dart';
import '../service/cart_service.dart';
import '../service/product_service.dart';
import '../service/notification_service.dart';

class OrderService {
  // =============================
  // GET ORDERS BY USER
  // =============================
  Future<List<Order>> getOrdersByUser(int userId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return result.map((e) => Order.fromMap(e)).toList();
  }
  final cartService = CartService.instance;
  final productService = ProductService();

  // =============================
  // GET ORDERS (GIỮ NGUYÊN)
  // =============================
  Future<List<Order>> getOrders() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('orders', orderBy: 'id DESC');

    return result.map((e) => Order.fromMap(e)).toList();
  }

  // =============================
  // UPDATE STATUS (GIỮ NGUYÊN)
  // =============================
  Future<void> updateStatus(int id, String status) async {
    final db = await DatabaseService.instance.database;

    // Lấy thông tin đơn hàng để lấy userId
    final orderList = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    int? userId;
    if (orderList.isNotEmpty) {
      userId = orderList.first['user_id'] as int?;
    }

    await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Gửi thông báo cho user
    if (userId != null) {
      String title = 'Cập nhật trạng thái đơn hàng';
      String body = 'Đơn hàng #$id của bạn đã chuyển sang trạng thái: $status.';
      await NotificationService.instance.addNotification(
        title: title,
        body: body,
        userId: userId,
        createdAt: DateTime.now().toString(),
      );
    }
  }

  // =============================
  // 🔥 CHECKOUT (THÊM MỚI)
  // =============================
  Future<int> checkout({
    required int userId,
    required int addressId,
    required String paymentMethod,
  }) async {
    final db = await DatabaseService.instance.database;

    final cartItems = await cartService.getAll();

    double total = 0;

    // tính tổng tiền
    for (var item in cartItems) {
      final product = await productService.getById(item.productId);
      total += product.price * item.quantity;
    }

    // tạo order
    int orderId = await db.insert('orders', {
      'user_id': userId,
      'total': total,
      'status': 'Pending',
      'payment_method': paymentMethod,
      'address_id': addressId,
      'created_at': DateTime.now().toString(),
    });

    // tạo order_items
    for (var item in cartItems) {
      final product = await productService.getById(item.productId);

      await db.insert('order_items', {
        'order_id': orderId,
        'product_id': item.productId,
        'quantity': item.quantity,
        'price': product.price,
      });
    }

    // Gửi thông báo đặt hàng thành công cho user
    await NotificationService.instance.addNotification(
      title: 'Đặt hàng thành công',
      body: 'Bạn đã đặt đơn hàng #$orderId thành công. Cảm ơn bạn đã mua sắm!',
      userId: userId,
      createdAt: DateTime.now().toString(),
    );

    // clear cart
    await cartService.clear();
    return orderId;
}

  // =============================
  // 🔥 GET ORDER DETAIL (THÊM MỚI)
  // =============================
  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final db = await DatabaseService.instance.database;

    return await db.rawQuery('''
      SELECT oi.*, p.name, p.image
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      WHERE oi.order_id = ?
    ''', [orderId]);
  }

  
}