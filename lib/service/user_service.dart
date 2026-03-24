
import 'package:sqflite/sqflite.dart';
import '../entity/user.dart';
import 'database_service.dart';
import 'auth_service.dart';

class UserService {

  // Lấy user theo id
  Future<User?> getUserById(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      'users',
      where: 'id = ? AND COALESCE(is_active, 1) = 1',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }
  final auth = AuthService();

  Future<List<User>> getAllUsers({bool includeInactive = false}) async {
    final db = await DatabaseService.instance.database;
    final result = includeInactive
        ? await db.query('users')
        : await db.query(
            'users',
            where: 'COALESCE(is_active, 1) = 1',
          );
    return result.map((e) => User.fromMap(e)).toList();
  }

  Future<void> insertUser(User user) async {
    final db = await DatabaseService.instance.database;
    final hashedPassword = auth.isHashedPassword(user.password)
        ? user.password
        : auth.hashPassword(user.password);
    await db.insert(
      'users',
      {
        ...user.toMap(),
        'password': hashedPassword,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteUser(int id) async {
    return deactivateUser(id);
  }

  Future<int> deactivateUser(int id) async {
    final db = await DatabaseService.instance.database;
    await db.delete(
      'session',
      where: 'user_id = ?',
      whereArgs: [id],
    );
    return await db.update(
      'users',
      {'is_active': 0},
      where: 'id = ? AND COALESCE(is_active, 1) = 1',
      whereArgs: [id],
    );
  }

  Future<int> activateUser(int id) async {
    final db = await DatabaseService.instance.database;
    return await db.update(
      'users',
      {'is_active': 1},
      where: 'id = ? AND COALESCE(is_active, 1) = 0',
      whereArgs: [id],
    );
  }

  // GET CURRENT USER
  Future<User?> getCurrentUser() async {
    final db = await DatabaseService.instance.database;
    final userId = await auth.getCurrentUserId();
    if (userId == null) return null;
    final result = await db.query(
      'users',
      where: 'id = ? AND COALESCE(is_active, 1) = 1',
      whereArgs: [userId],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // UPDATE USER
  Future<void> updateUser(User user) async {
    final db = await DatabaseService.instance.database;
    final hashedPassword = auth.isHashedPassword(user.password)
        ? user.password
        : auth.hashPassword(user.password);
    await db.update(
      'users',
      {
        ...user.toMap(),
        'password': hashedPassword,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}
