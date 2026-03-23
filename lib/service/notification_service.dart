import 'package:sqflite/sqflite.dart';
import 'database_service.dart';


class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();
  final db = DatabaseService.instance;

  // Lấy tất cả thông báo của userId (nếu null thì lấy tất cả)
  Future<List<Map<String, dynamic>>> getAllNotifications({int? userId}) async {
    final database = await db.database;
    List<Map<String, dynamic>> result;
    if (userId != null) {
      result = await database.query(
        'notifications',
        where: 'user_id = ? OR user_id IS NULL',
        whereArgs: [userId],
        orderBy: 'id DESC',
      );
    } else {
      result = await database.query('notifications', orderBy: 'id DESC');
    }
    return result;
  }

  // Hàm thêm thông báo mới cho user cụ thể
  Future<void> addNotification({
    required String title,
    required String body,
    required String createdAt,
    int? userId,
  }) async {
    final database = await db.database;
    await database.insert('notifications', {
      'title': title,
      'body': body,
      'user_id': userId,
      'created_at': createdAt,
    });
  }
}
