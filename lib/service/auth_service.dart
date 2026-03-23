
import '../entity/user.dart';
import 'database_service.dart';

class AuthService {
  // LOGIN
   Future<User?> login(String username, String password) async {
    final db = await DatabaseService.instance.database;

    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      final user = User.fromMap(result.first);

      // lưu session
      await db.delete('session');
      await db.insert('session', {
        'user_id': user.id,
      });

      return user; // ✅ QUAN TRỌNG
    }

    return null;
  }

  // REGISTER user sử dụng toMap để lưu vào database
  Future<bool> register(User user) async {
    final db = await DatabaseService.instance.database;

    final existing = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [user.username],
    );

    if (existing.isNotEmpty) return false;

    await db.insert('users', user.toMap());
    return true;
  }

  // GET CURRENT USER ID
  Future<int?> getCurrentUserId() async {
    final db = await DatabaseService.instance.database;

    final session = await db.query('session', limit: 1);

    if (session.isEmpty) return null;

    return session.first['user_id'] as int;
  }

  // LOGOUT
  Future<void> logout() async {
    final db = await DatabaseService.instance.database;
    await db.delete('session');
  }
}

