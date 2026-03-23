import '../entity/product.dart';
import 'audit_log_service.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'product_service.dart';
import 'user_service.dart';

class InventoryService {
  final _productService = ProductService();
  final _userService = UserService();
  final _notificationService = NotificationService.instance;

  Future<Product> updateStock({
    required int productId,
    required int newQuantity,
    required int actorUserId,
  }) async {
    final quantity = newQuantity < 0 ? 0 : newQuantity;

    final current = await _productService.getById(productId);
    if (current.quantity == quantity) {
      return current;
    }

    final db = await DatabaseService.instance.database;
    await db.update(
      'products',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [productId],
    );

    await AuditLogService.instance.logStockUpdate(
      actorUserId: actorUserId,
      productId: productId,
      oldQuantity: current.quantity,
      newQuantity: quantity,
    );

    final updated = await _productService.getById(productId);
    await _notifyAdminIfStaffUpdatedStock(
      actorUserId: actorUserId,
      product: updated,
      oldQuantity: current.quantity,
      newQuantity: quantity,
    );

    return updated;
  }

  Future<void> _notifyAdminIfStaffUpdatedStock({
    required int actorUserId,
    required Product product,
    required int oldQuantity,
    required int newQuantity,
  }) async {
    final actor = await _userService.getUserById(actorUserId);
    if (actor == null || actor.role != 'staff') return;

    final actorName = (actor.fullName?.trim().isNotEmpty ?? false)
        ? actor.fullName!.trim()
        : actor.username;
    final delta = newQuantity - oldQuantity;
    final deltaText = delta >= 0 ? '+$delta' : '$delta';

    await _notificationService.addNotificationToRole(
      role: 'admin',
      title: 'Staff updated inventory',
      body:
          '$actorName updated stock for product #${product.id}: ${product.name}. Qty: $oldQuantity -> $newQuantity ($deltaText).',
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}
