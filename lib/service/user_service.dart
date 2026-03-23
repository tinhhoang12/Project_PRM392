
import 'package:sqflite/sqflite.dart';
import '../entity/user.dart';
import 'database_service.dart';
import 'auth_service.dart';

class UserService {

  // Lấy user theo id
  Future<User?> getUserById(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }
  final auth = AuthService();

  Future<List<User>> getAllUsers() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('users');
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
    final db = await DatabaseService.instance.database;
    return await db.delete(
      'users',
      where: 'id = ?',
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
      where: 'id = ?',
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
