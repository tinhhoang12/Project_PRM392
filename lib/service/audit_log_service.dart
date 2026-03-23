import 'database_service.dart';

class AuditLogService {
  AuditLogService._();
  static final AuditLogService instance = AuditLogService._();

  Future<void> logStockUpdate({
    required int actorUserId,
    required int productId,
    required int oldQuantity,
    required int newQuantity,
  }) async {
    final db = await DatabaseService.instance.database;
    await db.insert('audit_logs', {
      'actor_user_id': actorUserId,
      'action': 'update_stock',
      'target_type': 'product',
      'target_id': productId,
      'old_value': oldQuantity.toString(),
      'new_value': newQuantity.toString(),
      'created_at': DateTime.now().toString(),
    });
  }

  Future<List<Map<String, dynamic>>> getStockLogs({int limit = 50}) async {
    final db = await DatabaseService.instance.database;
    return db.query(
      'audit_logs',
      where: 'action = ?',
      whereArgs: ['update_stock'],
      orderBy: 'id DESC',
      limit: limit,
    );
  }
}
