import 'database_service.dart';

class ReviewService {
  final _dbService = DatabaseService.instance;

  Future<Map<String, dynamic>> getRatingSummary(int productId) async {
    final db = await _dbService.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total_reviews,
        AVG(rating) AS avg_rating
      FROM product_reviews
      WHERE product_id = ?
      ''',
      [productId],
    );

    final row = rows.first;
    return {
      'total_reviews': (row['total_reviews'] as int?) ?? 0,
      'avg_rating': (row['avg_rating'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getReviewsByProduct(int productId) async {
    final db = await _dbService.database;
    return db.rawQuery(
      '''
      SELECT
        r.id,
        r.product_id,
        r.user_id,
        r.rating,
        r.comment,
        r.created_at,
        COALESCE(u.full_name, u.username, 'User') AS reviewer_name
      FROM product_reviews r
      LEFT JOIN users u ON r.user_id = u.id
      WHERE r.product_id = ?
      ORDER BY r.created_at DESC
      ''',
      [productId],
    );
  }

  Future<void> upsertReview({
    required int productId,
    required int userId,
    required int rating,
    required String comment,
  }) async {
    final db = await _dbService.database;
    final now = DateTime.now().toIso8601String();

    final existing = await db.query(
      'product_reviews',
      columns: ['id'],
      where: 'product_id = ? AND user_id = ?',
      whereArgs: [productId, userId],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('product_reviews', {
        'product_id': productId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
        'created_at': now,
      });
      return;
    }

    await db.update(
      'product_reviews',
      {
        'rating': rating,
        'comment': comment,
        'created_at': now,
      },
      where: 'product_id = ? AND user_id = ?',
      whereArgs: [productId, userId],
    );
  }
}
