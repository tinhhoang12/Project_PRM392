import 'database_service.dart';
import 'package:sqflite/sqflite.dart';

class LowStockAlertService {
  final _dbService = DatabaseService.instance;

  Future<void> clearMutedForResolvedProducts({int threshold = 5}) async {
    final db = await _dbService.database;
    await db.rawDelete(
      '''
      DELETE FROM low_stock_alert_preferences
      WHERE product_id IN (
        SELECT id FROM products WHERE quantity > ?
      )
      ''',
      [threshold],
    );
  }

  Future<Set<int>> getMutedProductIds(Iterable<int> productIds) async {
    final ids = productIds.toList();
    if (ids.isEmpty) return <int>{};

    final db = await _dbService.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery(
      '''
      SELECT product_id
      FROM low_stock_alert_preferences
      WHERE product_id IN ($placeholders)
      ''',
      ids,
    );

    return rows
        .map((e) => e['product_id'] as int?)
        .whereType<int>()
        .toSet();
  }

  Future<void> muteProducts(Iterable<int> productIds) async {
    final ids = productIds.toSet();
    if (ids.isEmpty) return;

    final db = await _dbService.database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final id in ids) {
      batch.insert(
        'low_stock_alert_preferences',
        {
          'product_id': id,
          'muted_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
