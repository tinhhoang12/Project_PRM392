import '../entity/order.dart';
import '../service/cart_service.dart';
import '../service/database_service.dart';
import '../service/notification_service.dart';

class OrderService {
  final cartService = CartService.instance;

  static const String pending = 'Pending';
  static const String confirmed = 'Confirmed';
  static const String shipping = 'Shipping';
  static const String delivered = 'Delivered';
  static const String cancelled = 'Cancelled';

  static const Map<String, Set<String>> _allowedTransitions = {
    pending: {confirmed, cancelled},
    confirmed: {shipping, cancelled},
    shipping: {delivered},
    delivered: {},
    cancelled: {},
  };

  String _normalizeStatus(String? status) {
    final raw = (status ?? '').trim().toLowerCase();
    switch (raw) {
      case 'pending':
        return pending;
      case 'confirmed':
      case 'confirm':
        return confirmed;
      case 'shipping':
        return shipping;
      case 'delivered':
        return delivered;
      case 'cancelled':
      case 'canceled':
        return cancelled;
      default:
        return status?.trim().isNotEmpty == true ? status!.trim() : pending;
    }
  }

  List<String> getAllowedStatusTransitions(String currentStatus) {
    final normalized = _normalizeStatus(currentStatus);
    return (_allowedTransitions[normalized] ?? const <String>{}).toList();
  }

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

  Future<List<Order>> getOrders() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('orders', orderBy: 'id DESC');
    return result.map((e) => Order.fromMap(e)).toList();
  }

  Future<void> updateStatus(int id, String nextStatus) async {
    final db = await DatabaseService.instance.database;
    int? notifyUserId;
    late String notifyStatus;

    await db.transaction((txn) async {
      final orderList = await txn.query('orders', where: 'id = ?', whereArgs: [id]);
      if (orderList.isEmpty) {
        throw Exception('Order #$id not found');
      }

      final currentStatus = _normalizeStatus(orderList.first['status'] as String?);
      final userId = orderList.first['user_id'] as int?;
      final paymentMethod =
          (orderList.first['payment_method'] as String? ?? '').toLowerCase();
      final normalizedNextStatus = _normalizeStatus(nextStatus);
      notifyStatus = normalizedNextStatus;

      if (currentStatus == normalizedNextStatus) {
        return;
      }

      final allowed = _allowedTransitions[currentStatus] ?? const <String>{};
      if (!allowed.contains(normalizedNextStatus)) {
        throw Exception('Invalid status transition: $currentStatus -> $normalizedNextStatus');
      }

      if (normalizedNextStatus == cancelled) {
        final items = await txn.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [id],
        );

        for (final item in items) {
          final productId = item['product_id'] as int?;
          final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
          if (productId == null || quantity <= 0) continue;

          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity + ? WHERE id = ?',
            [quantity, productId],
          );
        }
      }

      final updateData = <String, dynamic>{'status': normalizedNextStatus};
      if (normalizedNextStatus == confirmed && paymentMethod == 'qr') {
        updateData['payment_status'] = 'paid';
      }
      if (normalizedNextStatus == delivered) {
        updateData['user_received_confirmed'] = 0;
      }

      await txn.update(
        'orders',
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );
      notifyUserId = userId;
    });

    if (notifyUserId != null) {
      await NotificationService.instance.addNotification(
        title: 'Cap nhat trang thai don hang',
        body: 'Don hang #$id cua ban da chuyen sang trang thai: $notifyStatus.',
        userId: notifyUserId,
        createdAt: DateTime.now().toString(),
      );
    }
  }

  Future<void> confirmReceived({
    required int orderId,
    required int userId,
  }) async {
    final db = await DatabaseService.instance.database;
    bool shouldNotify = false;
    await db.transaction((txn) async {
      final orderList = await txn.query(
        'orders',
        where: 'id = ?',
        whereArgs: [orderId],
        limit: 1,
      );

      if (orderList.isEmpty) {
        throw Exception('Order #$orderId not found');
      }

      final order = orderList.first;
      final ownerId = order['user_id'] as int?;
      final currentStatus = _normalizeStatus(order['status'] as String?);

      if (ownerId != userId) {
        throw Exception('You do not have permission to confirm this order');
      }

      if (currentStatus != shipping) {
        throw Exception('Only shipping orders can be marked as received');
      }

      await txn.update(
        'orders',
        {
          'status': delivered,
          'user_received_confirmed': 1,
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );
      shouldNotify = true;
    });

    if (shouldNotify) {
      await NotificationService.instance.addNotification(
        title: 'Cap nhat trang thai don hang',
        body: 'Don hang #$orderId cua ban da chuyen sang trang thai: $delivered.',
        userId: userId,
        createdAt: DateTime.now().toString(),
      );
    }
  }

  Future<int> checkout({
    required int userId,
    required int addressId,
    required String paymentMethod,
  }) async {
    final db = await DatabaseService.instance.database;
    late int orderId;
    late String normalizedPaymentMethod;

    await db.transaction<void>((txn) async {
      final addressRows = await txn.query(
        'addresses',
        where: 'id = ? AND user_id = ?',
        whereArgs: [addressId, userId],
        limit: 1,
      );
      if (addressRows.isEmpty) {
        throw Exception('Invalid address for current user');
      }
      final address = addressRows.first;

      final cartItems = await txn.query(
        'cart',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'id DESC',
      );
      if (cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      double subtotal = 0;
      for (final item in cartItems) {
        final productId = item['product_id'] as int?;
        final orderedQty = (item['quantity'] as num?)?.toInt() ?? 0;
        final itemPrice = (item['price'] as num?)?.toDouble() ?? 0;
        if (productId == null || orderedQty <= 0) {
          throw Exception('Invalid cart item detected');
        }

        final productRows = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );
        if (productRows.isEmpty) {
          throw Exception('Product #$productId not found');
        }

        final stock = (productRows.first['quantity'] as num?)?.toInt() ?? 0;
        final name = productRows.first['name']?.toString() ?? 'Product #$productId';
        if (orderedQty > stock) {
          throw Exception('Insufficient stock for $name. Available: $stock');
        }

        subtotal += itemPrice * orderedQty;
      }

      const discountAmount = 0.0;
      const shippingFee = 0.0;
      final total = subtotal - discountAmount + shippingFee;
      normalizedPaymentMethod = paymentMethod.toLowerCase();
      final paymentStatus = normalizedPaymentMethod == 'qr' ||
              normalizedPaymentMethod == 'cod'
          ? 'pending'
          : 'paid';

      orderId = await txn.insert('orders', {
        'user_id': userId,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'user_received_confirmed': 0,
        'address_id': addressId,
        'receiver_name': address['name'],
        'receiver_phone': address['phone'],
        'receiver_address': address['address'],
        'subtotal': subtotal,
        'discount_amount': discountAmount,
        'shipping_fee': shippingFee,
        'total': total,
        'status': pending,
        'created_at': DateTime.now().toString(),
      });

      for (final item in cartItems) {
        final productId = item['product_id'] as int;
        final orderedQty = (item['quantity'] as num).toInt();
        final itemPrice = (item['price'] as num).toDouble();

        await txn.insert('order_items', {
          'order_id': orderId,
          'product_id': productId,
          'quantity': orderedQty,
          'price': itemPrice,
        });

        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity - ? WHERE id = ?',
          [orderedQty, productId],
        );
      }

      await txn.delete(
        'cart',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    });

    await NotificationService.instance.addNotification(
      title: 'Dat hang thanh cong',
      body: 'Ban da dat don hang #$orderId thanh cong. Cam on ban da mua sam!',
      userId: userId,
      createdAt: DateTime.now().toString(),
    );

    if (normalizedPaymentMethod == 'qr') {
      await NotificationService.instance.addNotificationToRole(
        role: 'staff',
        title: 'QR payment submitted',
        body: 'Order #$orderId has been marked paid by customer (QR).',
        createdAt: DateTime.now().toIso8601String(),
      );
    }

    return orderId;
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final db = await DatabaseService.instance.database;

    return db.rawQuery('''
      SELECT oi.*, p.name, p.image
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      WHERE oi.order_id = ?
    ''', [orderId]);
  }
}
