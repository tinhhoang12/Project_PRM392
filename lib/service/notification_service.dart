import 'database_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final db = DatabaseService.instance;

  Future<List<Map<String, dynamic>>> getAllNotifications({int? userId}) async {
    final database = await db.database;
    if (userId != null) {
      return database.query(
        'notifications',
        where: 'user_id = ? OR user_id IS NULL',
        whereArgs: [userId],
        orderBy: 'id DESC',
      );
    }

    return database.query('notifications', orderBy: 'id DESC');
  }

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

  Future<void> addNotificationToRole({
    required String role,
    required String title,
    required String body,
    String? createdAt,
  }) async {
    final database = await db.database;
    final users = await database.query(
      'users',
      columns: ['id'],
      where: 'role = ?',
      whereArgs: [role],
    );

    final now = createdAt ?? DateTime.now().toIso8601String();
    for (final user in users) {
      final userId = user['id'] as int?;
      if (userId == null) continue;
      await addNotification(
        title: title,
        body: body,
        userId: userId,
        createdAt: now,
      );
    }
  }

  Future<int> getUnreadCount({required int userId}) async {
    final database = await db.database;
    final result = await database.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM notifications
      WHERE (user_id = ? OR user_id IS NULL) AND is_read = 0
      ''',
      [userId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> markAsRead(int id) async {
    final database = await db.database;
    await database.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
