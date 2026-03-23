import 'package:sqflite/sqflite.dart';

import 'database_service.dart';

class AdminService {
  Future<double> getTodayRevenue() async {
    final db = await DatabaseService.instance.database;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    final result = await db.rawQuery('''
      SELECT SUM(total) as total
      FROM orders
      WHERE DATE(created_at) = ?
    ''', [today]);

    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> getTotalOrders() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM orders');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalProducts() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getLowStockCount({int threshold = 5}) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE quantity <= ?',
      [threshold],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalUsers() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getRecentOrders() async {
    final db = await DatabaseService.instance.database;

    return db.rawQuery('''
      SELECT
        o.id,
        o.status,
        o.total,
        o.created_at,
        p.name AS product_name,
        p.image AS product_image
      FROM orders o
      LEFT JOIN order_items oi ON oi.order_id = o.id
      LEFT JOIN products p ON p.id = oi.product_id
      WHERE oi.id = (
        SELECT oi2.id
        FROM order_items oi2
        WHERE oi2.order_id = o.id
        ORDER BY oi2.id ASC
        LIMIT 1
      )
      ORDER BY o.created_at DESC
      LIMIT 5
    ''');
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts({
    int threshold = 5,
    int limit = 10,
  }) async {
    final db = await DatabaseService.instance.database;
    return db.query(
      'products',
      where: 'quantity <= ?',
      whereArgs: [threshold],
      orderBy: 'quantity ASC, id DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getRevenueLastNDays({int days = 7}) async {
    final db = await DatabaseService.instance.database;
    final start = DateTime.now().subtract(Duration(days: days - 1));
    final dateKeys = List.generate(
      days,
      (index) => start.add(Duration(days: index)).toIso8601String().substring(0, 10),
    );

    final rows = await db.rawQuery(
      '''
      SELECT DATE(created_at) as day, SUM(total) as revenue
      FROM orders
      WHERE DATE(created_at) >= ?
      GROUP BY DATE(created_at)
      ''',
      [dateKeys.first],
    );

    final revenueByDay = <String, double>{};
    for (final row in rows) {
      final day = row['day']?.toString();
      if (day == null) continue;
      revenueByDay[day] = (row['revenue'] as num?)?.toDouble() ?? 0;
    }

    return dateKeys
        .map((day) => {
              'day': day,
              'revenue': revenueByDay[day] ?? 0.0,
            })
        .toList();
  }
}
