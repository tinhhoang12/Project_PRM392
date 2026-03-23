import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class AdminService {
  // Tổng doanh thu hôm nay
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

  // Tổng orders
  Future<int> getTotalOrders() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM orders');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Tổng products
  Future<int> getTotalProducts() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Tổng users
  Future<int> getTotalUsers() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Recent orders
  Future<List<Map<String, dynamic>>> getRecentOrders() async {
    final db = await DatabaseService.instance.database;

    return await db.query(
      'orders',
      orderBy: 'created_at DESC',
      limit: 5,
    );
  }
}